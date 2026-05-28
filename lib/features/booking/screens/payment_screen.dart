import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums.dart';
import '../providers/booking_provider.dart';

enum _Step { form, processing, success }

/// V4 Payment — fully themed (light/dark) + localized (EN/AR)
class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _numCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _Step _step = _Step.form;

  late AnimationController _spinCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successScale =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BookingProvider>();
      if (p.booking?.id != widget.bookingId) p.loadBooking(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _spinCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = _Step.processing);
    final ok = await context.read<BookingProvider>().processMockPayment();
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _Step.success);
      _successCtrl.forward();
    } else {
      setState(() => _step = _Step.form);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(context.read<BookingProvider>().error ?? t.somethingWrong)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _step == _Step.form,
      child: Scaffold(
        appBar: _step != _Step.success
            ? AppBar(
                title: Text(t.paymentDetails),
                leading: _step == _Step.form && context.canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 17),
                        onPressed: () => context.pop())
                    : null,
              )
            : null,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: switch (_step) {
            _Step.form => _buildForm(t, cs),
            _Step.processing => _buildProcessing(t, cs),
            _Step.success => _buildSuccess(t, cs),
          },
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations t, ColorScheme cs) {
    return Consumer<BookingProvider>(builder: (_, provider, __) {
      final booking = provider.booking;
      final car = provider.car;
      final fmtP = NumberFormat('#,###');
      final fmt = DateFormat('dd/MM/yyyy');
      final days = booking != null
          ? booking.endDate.difference(booking.startDate).inDays.clamp(1, 9999)
          : 1;

      return SingleChildScrollView(
        key: const ValueKey('form'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _StepDots(current: 2),
            const SizedBox(height: 18),

            // Amount banner
            if (booking != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.amountDue,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                'EGP ${fmtP.format(booking.totalPrice.round())}',
                                style: TextStyle(
                                    color: cs.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22)),
                          ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.lock_outline,
                              color: cs.secondary, size: 13),
                          const SizedBox(width: 4),
                          Text(t.secure,
                              style: TextStyle(
                                  color: cs.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
              ),
            const SizedBox(height: 16),

            // Card visual
            _CardVisual(
                number: _numCtrl.text,
                name: _nameCtrl.text,
                expiry: _expiryCtrl.text),
            const SizedBox(height: 16),

            // Card number
            _FieldLabel(t.cardNumber),
            const SizedBox(height: 7),
            _CardField(
              controller: _numCtrl,
              hint: t.cardNumberHint,
              keyboard: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardFmt(),
                LengthLimitingTextInputFormatter(19)
              ],
              onChanged: (_) => setState(() {}),
              validator: (v) => (v?.replaceAll(' ', '').length ?? 0) < 16
                  ? t.enter16Digits
                  : null,
            ),
            const SizedBox(height: 12),

            // Name
            _FieldLabel(t.cardholderName),
            const SizedBox(height: 7),
            _CardField(
              controller: _nameCtrl,
              hint: t.cardholderHint,
              capitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.enterName : null,
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(t.expiry),
                  const SizedBox(height: 7),
                  _CardField(
                    controller: _expiryCtrl,
                    hint: 'MM/YY',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFmt(),
                      LengthLimitingTextInputFormatter(5)
                    ],
                    validator: (v) => (v?.length ?? 0) < 5 ? t.required : null,
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(t.cvv),
                  const SizedBox(height: 7),
                  _CardField(
                    controller: _cvvCtrl,
                    hint: '•••',
                    keyboard: TextInputType.number,
                    obscure: true,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3)
                    ],
                    validator: (v) => (v?.length ?? 0) < 3 ? t.required : null,
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 16),

            // Booking summary
            if (booking != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.bookingInformation,
                          style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      _SumRow(
                          car != null
                              ? '${car.brand} ${car.model} ${car.year}'
                              : '—',
                          t.bookingId,
                          booking.id.substring(0, 8).toUpperCase()),
                      _SumRow2(t.pickupDate, fmt.format(booking.startDate)),
                      _SumRow2(t.returnDate, fmt.format(booking.endDate)),
                      _SumRow2(t.duration,
                          '${booking.endDate.difference(booking.startDate).inDays.clamp(1, 9999)} ${t.days}'),
                      Divider(color: cs.outlineVariant, height: 20),
                      Text(t.payment,
                          style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 10),
                      _SumRow2(t.carRental,
                          'EGP ${fmtP.format(booking.totalPrice.round())}'),
                      Divider(color: cs.outlineVariant, height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t.totalAmount,
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text(
                                'EGP ${fmtP.format(booking.totalPrice.round())}',
                                style: TextStyle(
                                    color: cs.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ]),
                    ]),
              ),
            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: cs.secondary, size: 15),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t.mockPaymentNote,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 22),

            _GoldBtn(
              label: booking != null
                  ? t.confirmPayAmount(
                      NumberFormat('#,###').format(booking.totalPrice.round()))
                  : t.confirmPayment,
              onPressed: _pay,
            ),
            const SizedBox(height: 20),
          ]),
        ),
      );
    });
  }

  Widget _buildProcessing(AppLocalizations t, ColorScheme cs) => Center(
        key: const ValueKey('processing'),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RotationTransition(
            turns: _spinCtrl,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.secondary, width: 3)),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: cs.secondary)),
            ),
          ),
          const SizedBox(height: 24),
          Text(t.processingPayment,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(t.doNotClose,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ]),
      );

  Widget _buildSuccess(AppLocalizations t, ColorScheme cs) {
    return Consumer<BookingProvider>(builder: (_, provider, __) {
      final booking = provider.booking;
      final car = provider.car;
      final fmtP = NumberFormat('#,###');
      final fmt = DateFormat('dd/MM/yyyy');

      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('success'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t.paymentStatus,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.more_horiz,
                      color: cs.onSurfaceVariant, size: 18),
                ),
              ]),
              const SizedBox(height: 26),
              Center(
                  child: Column(children: [
                ScaleTransition(
                  scale: _successScale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.paymentSuccessful,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(t.bookingConfirmedSub,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ])),
              const SizedBox(height: 26),
              if (booking != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.bookingInformation,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 12),
                        if (car != null)
                          _SumRow2('${car.brand} ${car.model} ${car.year}', ''),
                        _SumRow2(t.bookingId,
                            booking.id.substring(0, 8).toUpperCase()),
                        _SumRow2(t.pickupDate, fmt.format(booking.startDate)),
                        _SumRow2(t.returnDate, fmt.format(booking.endDate)),
                        Divider(color: cs.outlineVariant, height: 20),
                        Text(t.payment,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 10),
                        _SumRow2(t.amountDue,
                            'EGP ${fmtP.format(booking.totalPrice.round())}',
                            valueColor: cs.secondary),
                        _SumRow2(
                            t.payment,
                            booking.paymentStatus == PaymentStatus.paid
                                ? t.paidStatus
                                : booking.paymentStatus.name,
                            valueColor:
                                booking.paymentStatus == PaymentStatus.paid
                                    ? Colors.green
                                    : cs.secondary),
                        Divider(color: cs.outlineVariant, height: 16),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.totalAmount,
                                  style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(
                                  'EGP ${fmtP.format(booking.totalPrice.round())}',
                                  style: TextStyle(
                                      color: cs.secondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)),
                            ]),
                      ]),
                ),
              const SizedBox(height: 20),
              _GoldBtn(
                label: t.viewBookingDetails,
                onPressed: () => context.push('/booking/${widget.bookingId}'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    side: BorderSide(color: cs.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(t.backToHome,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// CARD VISUAL
// ─────────────────────────────────────────────
class _CardVisual extends StatelessWidget {
  final String number, name, expiry;
  const _CardVisual(
      {required this.number, required this.name, required this.expiry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final num =
        number.isEmpty ? '•••• •••• •••• ••••' : number.padRight(19, '•');
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [
          cs.primary,
          cs.primaryContainer,
          cs.primary.withValues(alpha: 0.8)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('DriveGO',
              style: TextStyle(
                  color: cs.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.8),
                    shape: BoxShape.circle)),
            Transform.translate(
                offset: const Offset(-10, 0),
                child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle))),
          ]),
        ]),
        const Spacer(),
        Text(num,
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 17,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CARDHOLDER',
                style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 1)),
            Text(name.isEmpty ? 'YOUR NAME' : name.toUpperCase(),
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('EXPIRES',
                style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 1)),
            Text(expiry.isEmpty ? 'MM/YY' : expiry,
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current;
  const _StepDots({required this.current});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
              color: done || active ? cs.secondary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GoldBtn({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600));
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final bool obscure;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _CardField(
      {required this.controller,
      required this.hint,
      this.keyboard,
      this.formatters,
      this.obscure = false,
      this.capitalization = TextCapitalization.none,
      this.onChanged,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      obscureText: obscure,
      textCapitalization: capitalization,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, label2, value;
  const _SumRow(this.label, this.label2, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SumRow2 extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SumRow2(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final s = b.toString();
    return n.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll('/', '');
    final b = StringBuffer();
    for (int i = 0; i < d.length && i < 4; i++) {
      if (i == 2) b.write('/');
      b.write(d[i]);
    }
    final s = b.toString();
    return n.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
