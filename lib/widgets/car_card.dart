import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// Drive Go's most-used widget. Displays one Car in a list/grid.
/// Used by V2 (Home, Search, Favorites), V3 (My Listings, Owner Profile),
/// and V5 (Rental History "rent again" section).
class CarCard extends StatelessWidget {
  final Car car;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const CarCard({
    super.key,
    required this.car,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0)
        .format(car.pricePerDay);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/car/${car.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + status badge + favorite button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: car.photos.isEmpty
                      ? Container(
                          color: theme.colorScheme.surface,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_car,
                            size: 60,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: car.photos.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surface,
                            alignment: Alignment.center,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surface,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusBadge(status: car.status),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.brand} ${car.model}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.year} Â· ${car.color}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(car.city, style: theme.textTheme.bodySmall),
                      const Spacer(),
                      Text(
                        '$price/day',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color-coded badge for the car listing status.
class _StatusBadge extends StatelessWidget {
  final CarStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CarStatus.available => (const Color(0xFF2E7D32), 'Available'),
      CarStatus.pendingConfirmation => (const Color(0xFFED6C02), 'Pending'),
      CarStatus.booked => (const Color(0xFFD32F2F), 'Booked'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        // Note: V2 owner â€” localize via app_en.arb / app_ar.arb
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
