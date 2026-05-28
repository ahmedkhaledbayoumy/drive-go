import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/models.dart';
import '../../../models/enums.dart';
import '../../../services/auth_provider.dart';
import '../providers/booking_provider.dart';

/// V4 Booking Details — fully themed (light/dark) + localized (EN/AR)
class BookingDetailsScreen extends StatefulWidget {
  final String? bookingId;
  final Car?    car;
  const BookingDetailsScreen({super.key, this.bookingId, this.car});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _pickupCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _withDriver = false;
  bool _submitting = false;

  bool get _isViewMode => widget.bookingId != null;

  int get _days {
    if (_startDate == null || _endDate == null) return 1;
    return _endDate!.difference(_startDate!).inDays.clamp(1, 9999);
  }

  double get _totalPrice {
    final car = widget.car;
    if (car == null) return 0;
    return car.pricePerDay * _days + (_withDriver ? 200.0 * _days : 0);
  }

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate   = DateTime.now().add(const Duration(days: 3));
    if (_isViewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          context.read<BookingProvider>().loadBooking(widget.bookingId!));
    }
  }

  @override
  void dispose() { _pickupCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final now    = DateTime.now();
    final cs     = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now)
                           : (_endDate ?? now.add(const Duration(days: 1))),
      firstDate: isStart ? now : (_startDate ?? now).add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: cs.copyWith(
            primary: cs.secondary,
            onPrimary: cs.onSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked))
          _endDate = picked.add(const Duration(days: 1));
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) return;
    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final provider = context.read<BookingProvider>();
    final booking = await provider.createBooking(
      carId:          widget.car!.id,
      customerId:     profile.id,
      ownerId:        widget.car!.ownerId,
      startDate:      _startDate!,
      endDate:        _endDate!,
      totalPrice:     _totalPrice,
      withDriver:     _withDriver,
      pickupLocation: _pickupCtrl.text.trim().isEmpty
                          ? null : _pickupCtrl.text.trim(),
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (booking != null) {
      context.push('/payment/${booking.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? t.failedCreateBooking)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isViewMode ? _buildView() : _buildCreate();
  }

  // ══════════════════════════════════════════
  // CREATE MODE
  // ══════════════════════════════════════════
  Widget _buildCreate() {
    final t    = AppLocalizations.of(context)!;
    final cs   = Theme.of(context).colorScheme;
    final car  = widget.car;
    final fmt  = DateFormat('dd MMM yyyy');
    final fmtP = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: Text(t.bookingDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (car != null) _CarCard(car: car),
          const SizedBox(height: 14),

          // Driver toggle
          _SectionCard(child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.bookWithDriver,
                    style: TextStyle(color: cs.onSurface,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(t.driverCostPerDay,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ]),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _withDriver,
                  onChanged: (v) => setState(() => _withDriver = v),
                  activeColor: cs.secondary,
                ),
              ),
            ],
          )),
          const SizedBox(height: 12),

          // Dates
          _SectionCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.rentalPeriod,
                  style: TextStyle(color: cs.onSurfaceVariant,
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DateTile(
                    label: t.pickupDate, date: _startDate,
                    onTap: () => _pickDate(true), fmt: fmt)),
                const SizedBox(width: 10),
                Expanded(child: _DateTile(
                    label: t.returnDate, date: _endDate,
                    onTap: () => _pickDate(false), fmt: fmt)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _days == 1 ? t.daysRental(1) : t.daysRentalPlural(_days),
                  style: TextStyle(color: cs.secondary,
                      fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          )),
          const SizedBox(height: 12),

          // Pickup location
          _SectionCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.pickupLocation,
                  style: TextStyle(color: cs.onSurfaceVariant,
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _pickupCtrl,
                decoration: InputDecoration(
                  hintText: t.pickupHint,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
            ],
          )),
          const SizedBox(height: 12),

          // Price breakdown
          if (car != null) _SectionCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.rentalCost,
                  style: TextStyle(color: cs.onSurfaceVariant,
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _PriceRow(
                  label: 'EGP ${car.pricePerDay.toStringAsFixed(0)}${t.perDay} × $_days',
                  value: 'EGP ${fmtP.format((car.pricePerDay * _days).round())}'),
              if (_withDriver)
                _PriceRow(
                    label: '${t.driver} ×$_days ${t.days}',
                    value: 'EGP ${fmtP.format(200 * _days)}'),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t.totalAmount,
                    style: TextStyle(color: cs.onSurface,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('EGP ${fmtP.format(_totalPrice.round())}',
                    style: TextStyle(color: cs.secondary,
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
            ],
          )),
          const SizedBox(height: 24),

          _GoldBtn(
            label: _submitting
                ? t.creatingBooking
                : t.payAmount(NumberFormat('#,###').format(_totalPrice.round())),
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════
  // VIEW MODE
  // ══════════════════════════════════════════
  Widget _buildView() {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Consumer<BookingProvider>(builder: (context, provider, _) {
      final booking = provider.booking;
      final car     = provider.car;
      final owner   = provider.ownerProfile;

      if (provider.isLoading && booking == null) {
        return Scaffold(body: Center(
            child: CircularProgressIndicator(color: cs.secondary)));
      }
      if (booking == null) {
        return Scaffold(body: Center(child: Text(t.bookingNotFound)));
      }

      final fmt  = DateFormat('dd MMM yyyy');
      final fmtP = NumberFormat('#,###');
      final days = booking.endDate.difference(booking.startDate).inDays.clamp(1, 9999);

      return Scaffold(
        appBar: AppBar(
          title: Text(t.bookingDetails),
          actions: [
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: cs.secondary, size: 20),
              onPressed: () => context.push('/chat/${booking.id}'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _StatusPill(status: booking.status),
            const SizedBox(height: 14),

            if (car != null) _CarCard(car: car),
            if (car != null) const SizedBox(height: 12),

            // Owner info
            if (owner != null) _SectionCard(child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: owner.avatarUrl != null
                    ? NetworkImage(owner.avatarUrl!) : null,
                child: owner.avatarUrl == null
                    ? Icon(Icons.person, color: cs.onSurfaceVariant, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(owner.fullName,
                      style: TextStyle(color: cs.onSurface,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (owner.phone != null)
                    Text(owner.phone!,
                        style: TextStyle(color: cs.onSurfaceVariant,
                            fontSize: 12)),
                ],
              )),
              if (owner.verified)
                Icon(Icons.verified, color: cs.secondary, size: 18),
            ])),
            const SizedBox(height: 12),

            // Booking info
            _SectionCard(child: Column(children: [
              _InfoRow(t.bookingId,
                  booking.id.substring(0, 8).toUpperCase(), mono: true),
              const _Div(),
              _InfoRow(t.from, fmt.format(booking.startDate)),
              const _Div(),
              _InfoRow(t.to, fmt.format(booking.endDate)),
              const _Div(),
              _InfoRow(t.duration, '$days ${t.days}'),
              const _Div(),
              _InfoRow(t.withDriver, booking.withDriver ? t.yes : t.no),
              if (booking.pickupLocation != null) ...[
                const _Div(),
                _InfoRow(t.pickup, booking.pickupLocation!),
              ],
            ])),
            const SizedBox(height: 12),

            // Payment info
            _SectionCard(child: Column(children: [
              _InfoRow(t.total,
                  'EGP ${fmtP.format(booking.totalPrice.round())}',
                  valueColor: cs.secondary, big: true),
              const _Div(),
              _InfoRow(t.payment,
                  booking.paymentStatus.name.toUpperCase(),
                  valueColor: booking.paymentStatus == PaymentStatus.paid
                      ? Colors.green : cs.secondary),
            ])),
            const SizedBox(height: 16),

            _OwnerActions(booking: booking),

            if (booking.status == BookingStatus.confirmed &&
                booking.paymentStatus == PaymentStatus.paid)
              const _PhonePrompt(),
          ]),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────
// SHARED COMPONENTS — all use Theme.of(context)
// ──────────────────────────────────────────────────────────

class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _GoldBtn({required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.onSecondary))
            : Text(label, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _CarCard extends StatelessWidget {
  final Car car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: car.photos.isNotEmpty
              ? Image.network(car.photos.first,
                  width: 80, height: 60, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(cs))
              : _placeholder(cs),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${car.brand} ${car.model} ${car.year}',
                style: TextStyle(color: cs.onSurface,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(car.city,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 5),
            Text('EGP ${car.pricePerDay.toStringAsFixed(0)}/day',
                style: TextStyle(color: cs.secondary,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        )),
      ]),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
      width: 80, height: 60,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.directions_car,
          color: cs.onSurfaceVariant, size: 30));
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final DateFormat fmt;
  const _DateTile({required this.label, required this.date,
      required this.onTap, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: date != null
                  ? cs.secondary.withValues(alpha: 0.5)
                  : cs.outline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant,
              fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date != null ? fmt.format(date!) : AppLocalizations.of(context)!.selectDate,
              style: TextStyle(color: cs.onSurface,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        Text(value, style: TextStyle(color: cs.onSurface,
            fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool mono, big;
  const _InfoRow(this.label, this.value,
      {this.valueColor, this.mono = false, this.big = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        Text(value, style: TextStyle(
            color: valueColor ?? cs.onSurface,
            fontSize: big ? 16 : 13,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            letterSpacing: mono ? 1.5 : 0)),
      ]),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();
  @override
  Widget build(BuildContext context) =>
      Divider(color: Theme.of(context).colorScheme.outlineVariant,
          height: 1, thickness: 1);
}

class _StatusPill extends StatelessWidget {
  final BookingStatus status;
  const _StatusPill({required this.status});

  Color _color(ColorScheme cs) {
    switch (status) {
      case BookingStatus.confirmed:  return Colors.green;
      case BookingStatus.pending:    return cs.secondary;
      case BookingStatus.declined:
      case BookingStatus.cancelled:  return cs.error;
      case BookingStatus.completed:  return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(status.name.toUpperCase(),
            style: TextStyle(color: color,
                fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  final Booking booking;
  const _OwnerActions({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t        = AppLocalizations.of(context)!;
    final cs       = Theme.of(context).colorScheme;
    final provider = context.read<BookingProvider>();
    final auth     = context.read<AuthProvider>();
    final isOwner  = auth.currentProfile?.id == booking.ownerId;
    if (!isOwner) return const SizedBox.shrink();

    if (booking.status == BookingStatus.pending) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => provider.transitionStatus(BookingStatus.declined),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
              child: Text(t.decline,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: _GoldBtn(
            label: t.confirm,
            onPressed: () => provider.transitionStatus(BookingStatus.confirmed),
          )),
        ]),
      );
    }
    if (booking.status == BookingStatus.confirmed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _GoldBtn(
          label: t.markCompleted,
          onPressed: () => provider.transitionStatus(BookingStatus.completed),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PhonePrompt extends StatelessWidget {
  const _PhonePrompt();

  @override
  Widget build(BuildContext context) {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.phone_in_talk, color: cs.secondary, size: 18),
          const SizedBox(width: 8),
          Text(t.phoneConfirmation,
              style: TextStyle(color: cs.secondary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Text(t.didOwnerMarkCar,
            style: TextStyle(color: cs.onSurface, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _GoldBtn(
            label: t.yes,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.enjoyRide))),
          )),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.supportFollowUp))),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outline),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
              child: Text(t.no,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          )),
        ]),
      ]),
    );
  }
}
