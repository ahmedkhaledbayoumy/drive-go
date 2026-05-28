import 'package:cached_network_image/cached_network_image.dart';
import 'package:drive_go/l10n/app_localizations.dart';
import 'package:drive_go/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../models/models.dart';

/// Drive Go's most-used widget. Displays one [Car] in a list/grid.
class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onBookNow;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const CarCard({
    super.key,
    required this.car,
    this.onBookNow,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final title = '${car.brand} ${car.model} ${car.year}';
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black26
        : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colorScheme.surface,
        child: InkWell(
          onTap: onTap ?? () => context.push('/car/${car.id}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CarImage(
                car: car,
                isFavorite: isFavorite,
                onFavoriteToggle: onFavoriteToggle,
                availableLabel: t.available,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t.carLocationLine(car.city, t.egyptSuffix),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        children: [
                          TextSpan(
                            text: 'EGP ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: car.pricePerDay.toStringAsFixed(0),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          TextSpan(text: t.perDay),
                        ],
                      ),
                    ),
                    if (onBookNow != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: onBookNow,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(t.bookNow),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarImage extends StatelessWidget {
  final Car car;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String availableLabel;

  const _CarImage({
    required this.car,
    required this.isFavorite,
    this.onFavoriteToggle,
    required this.availableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholderColor = colorScheme.onSurface.withValues(alpha: 0.12);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (car.photos.isEmpty)
            ColoredBox(
              color: placeholderColor,
              child: Center(
                child: Icon(
                  Icons.directions_car,
                  size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: car.photos.first,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => ColoredBox(
                color: placeholderColor,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: placeholderColor,
                child: const Icon(Icons.broken_image),
              ),
            ),
          if (car.status == CarStatus.available)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusAvailable,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  availableLabel,
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (onFavoriteToggle != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: onFavoriteToggle,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFavorite),
                      color: isFavorite
                          ? AppColors.statusBooked
                          : colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
