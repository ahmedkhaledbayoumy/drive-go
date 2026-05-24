import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

// ── BookingHistoryCard ────────────────────────────────────────────────────────
// Displays a single booking in the history list.
// Shows car image, title, dates, status chip, and action buttons.
// ─────────────────────────────────────────────────────────────────────────────

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({
    super.key,
    required this.booking,
    this.onRentAgain,
    this.onLeaveReview,
    this.onViewDetails,
  });

  final BookingSummary booking;
  final VoidCallback? onRentAgain;
  final VoidCallback? onLeaveReview;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car thumbnail
              _CarThumbnail(imageUrl: booking.carImageUrl),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            booking.carTitle.isNotEmpty
                                ? booking.carTitle
                                : 'Car Rental',
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Owner name
                    if (booking.ownerAccountType == 'dealership' &&
                        booking.dealershipName != null)
                      Text(
                        booking.dealershipName!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (booking.ownerName != null)
                      Text(
                        booking.ownerName!,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(height: 6),

                    // Date range
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(booking.startDate)} → ${_fmt(booking.endDate)}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      'EGP ${booking.totalPrice.toStringAsFixed(0)}  ·  ${booking.rentalDays} day${booking.rentalDays == 1 ? '' : 's'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      children: [
                        if (booking.canReview && onLeaveReview != null) ...[
                          _ActionButton(
                            label: 'Leave Review',
                            icon: Icons.star_outline_rounded,
                            color: cs.primary,
                            onTap: onLeaveReview!,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (booking.isPast && onRentAgain != null)
                          _ActionButton(
                            label: 'Rent Again',
                            icon: Icons.replay_rounded,
                            color: cs.secondary,
                            onTap: onRentAgain!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('MMM d, y').format(d);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CarThumbnail extends StatelessWidget {
  const _CarThumbnail({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 90,
        height: 80,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(cs),
              )
            : _placeholder(cs),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.directions_car_outlined,
            size: 36, color: cs.onSurfaceVariant),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'pending' => ('Pending', Colors.orange),
      'confirmed' => ('Confirmed', Colors.blue),
      'active' => ('Active', Colors.green),
      'completed' => ('Completed', cs.primary),
      'cancelled' => ('Cancelled', cs.error),
      'declined' => ('Declined', cs.error),
      _ => (status, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
