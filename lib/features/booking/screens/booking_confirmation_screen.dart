import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../providers/booking_provider.dart';

/// V4 Booking Confirmation — fully themed (light/dark) + localized (EN/AR)
class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  State<BookingConfirmationScreen> createState() => _State();
}

class _State extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BookingProvider>();
      if (p.booking?.id != widget.bookingId) {
        p.loadBooking(widget.bookingId);
      }
    });
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookingConfirmedTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Consumer<BookingProvider>(builder: (context, provider, _) {
        final booking = provider.booking;
        final car     = provider.car;
        final owner   = provider.ownerProfile;

        if (provider.isLoading && booking == null) {
          return Center(
              child: CircularProgressIndicator(color: cs.secondary));
        }
        if (booking == null) {
          return Center(child: Text(t.bookingNotFound));
        }

        final fmt  = DateFormat('dd MMM yyyy');
        final fmtP = NumberFormat('#,###');
        final days = booking.endDate
            .difference(booking.startDate).inDays.clamp(1, 9999);

        return FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(children: [
              const SizedBox(height: 10),

              // ── Success icon ──
              Container(
                width: 84, height: 84,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 46),
              ),
              const SizedBox(height: 14),
              Text(t.bookingRequestSent,
                  style: TextStyle(color: cs.onSurface,
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(t.ownerWillConfirm,
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 26),

              // ── Car card (READ: cars table) ──
              if (car != null) _CarCard(car: car),
              if (car != null) const SizedBox(height: 12),

              // ── Owner card (READ: profiles table) ──
              if (owner != null) _OwnerCard(owner: owner),
              if (owner != null) const SizedBox(height: 12),

              // ── Booking details (READ: bookings table) ──
              _InfoCard(
                title: t.bookingDetails,
                rows: [
                  _RowData(t.bookingId,
                      booking.id.substring(0, 8).toUpperCase(),
                      mono: true),
                  _RowData(t.from, fmt.format(booking.startDate)),
                  _RowData(t.to, fmt.format(booking.endDate)),
                  _RowData(t.duration, '$days ${t.days}'),
                  _RowData(t.withDriver,
                      booking.withDriver ? t.yes : t.no),
                  if (booking.pickupLocation != null)
                    _RowData(t.pickup, booking.pickupLocation!),
                ],
              ),
              const SizedBox(height: 12),

              // ── Payment card (READ: bookings.payment_status) ──
              _InfoCard(
                title: t.payment,
                rows: [
                  _RowData(t.total,
                      'EGP ${fmtP.format(booking.totalPrice.round())}',
                      valueColor: cs.secondary, big: true),
                  _RowData(t.payment,
                      booking.paymentStatus == PaymentStatus.paid
                          ? t.paidStatus : t.pending,
                      valueColor: booking.paymentStatus == PaymentStatus.paid
                          ? Colors.green : cs.secondary),
                  _RowData('Status',
                      booking.status.name.toUpperCase(),
                      valueColor: _statusColor(booking.status, cs)),
                ],
              ),
              const SizedBox(height: 26),

              // ── Chat button ──
              _GoldBtn(
                label: t.chatWithOwner,
                icon: Icons.chat_bubble_outline,
                onPressed: () =>
                    context.push('/chat/${booking.id}'),
              ),
              const SizedBox(height: 12),

              // ── View details ──
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/booking/${booking.id}'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text(t.viewFullDetails,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    side: BorderSide(color: cs.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(t.backToHome,
                    style: TextStyle(color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        );
      }),
    );
  }

  Color _statusColor(BookingStatus s, ColorScheme cs) {
    switch (s) {
      case BookingStatus.confirmed:  return Colors.green;
      case BookingStatus.pending:    return cs.secondary;
      case BookingStatus.declined:
      case BookingStatus.cancelled:  return cs.error;
      case BookingStatus.completed:  return Colors.blue;
    }
  }
}

// ──────────────────────────────────────────────────────────
// CAR CARD — READ: cars table
// ──────────────────────────────────────────────────────────
class _CarCard extends StatelessWidget {
  final Car car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: car.photos.isNotEmpty
              ? Image.network(car.photos.first,
                  width: 76, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(cs))
              : _placeholder(cs),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${car.brand} ${car.model} ${car.year}',
                style: TextStyle(color: cs.onSurface,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Text(car.city,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 5),
            Text('EGP ${car.pricePerDay.toStringAsFixed(0)}/day',
                style: TextStyle(color: cs.secondary,
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        )),
      ]),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
      width: 76, height: 56,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.directions_car,
          color: cs.onSurfaceVariant, size: 28));
}

// ──────────────────────────────────────────────────────────
// OWNER CARD — READ: profiles table
// ──────────────────────────────────────────────────────────
class _OwnerCard extends StatelessWidget {
  final Profile owner;
  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
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
            Row(children: [
              Text(owner.fullName,
                  style: TextStyle(color: cs.onSurface,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              if (owner.verified) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified, color: cs.secondary, size: 14),
              ],
            ]),
            const SizedBox(height: 3),
            Text(owner.accountType.name,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            if (owner.phone != null)
              Text(owner.phone!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          ],
        )),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────
// INFO CARD
// ──────────────────────────────────────────────────────────
class _RowData {
  final String label, value;
  final Color? valueColor;
  final bool mono, big;
  const _RowData(this.label, this.value,
      {this.valueColor, this.mono = false, this.big = false});
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_RowData> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: cs.onSurface,
            fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        ...rows.map((r) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(r.label, style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 13)),
              Flexible(child: Text(r.value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: r.valueColor ?? cs.onSurface,
                      fontSize: r.big ? 16 : 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: r.mono ? 'monospace' : null,
                      letterSpacing: r.mono ? 1.5 : 0))),
            ]),
          ),
          if (r != rows.last)
            Divider(color: cs.outlineVariant, height: 1, thickness: 1),
        ])),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────
// GOLD BUTTON
// ──────────────────────────────────────────────────────────
class _GoldBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const _GoldBtn({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 17, color: cs.onSecondary)
            : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
