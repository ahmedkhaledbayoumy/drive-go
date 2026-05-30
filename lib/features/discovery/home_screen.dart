import 'package:drive_go/features/discovery/models/filter_state.dart';
import 'package:drive_go/features/discovery/providers/discovery_provider.dart';
import 'package:drive_go/features/discovery/widgets/filter_bottom_sheet.dart';
import 'package:drive_go/features/discovery/widgets/main_bottom_nav.dart';
import 'package:drive_go/l10n/app_localizations.dart';
import 'package:drive_go/widgets/car_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _topBrands = [
    'Toyota',
    'Hyundai',
    'BMW',
    'KIA',
    'Mercedes',
    'Ford',
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = GoRouterState.of(context).matchedLocation;
    final heroBackground = theme.brightness == Brightness.dark
        ? (theme.appBarTheme.backgroundColor ?? colorScheme.surface)
        : colorScheme.primary;
    final onHero = theme.brightness == Brightness.dark
        ? (theme.appBarTheme.foregroundColor ?? colorScheme.onSurface)
        : colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ColoredBox(
              color: heroBackground,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Text(
                            t.driveGo,
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _AppBarPill(
                            label: t.all,
                            selected: location == '/home',
                            onTap: () => context.go('/home'),
                            onHero: onHero,
                          ),
                          _AppBarPill(
                            label: t.carsTab,
                            selected: location == '/search',
                            onTap: () => context.push('/search'),
                            onHero: onHero,
                          ),
                          _AppBarPill(
                            label: t.saved,
                            selected: location == '/favorites',
                            onTap: () => context.go('/favorites'),
                            onHero: onHero,
                          ),
                          IconButton(
                           icon: const Icon(Icons.account_circle_outlined),
                           color: onHero,
                           tooltip: 'Profile',
                          onPressed: () => context.push('/profile'),
                         ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.findYourRide,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onHero,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.homeTagline,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onHero.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    t.searchHint,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: colorScheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: t.topBrands,
                      onTap: () => _openFilters(context),
                    ),
                    _FilterChip(
                      label: t.models,
                      onTap: () => _openFilters(context),
                    ),
                    _FilterChip(
                      label: t.cities,
                      onTap: () => _openFilters(context),
                    ),
                    _FilterChip(
                      label: t.priceChip,
                      onTap: () => _openFilters(context),
                    ),
                    _FilterIconChip(
                      onTap: () => _openFilters(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      t.topBrands,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: Text(t.viewAll),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: colorScheme.surface,
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _topBrands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final brand = _topBrands[index];
                    return SizedBox(
                      width: 72,
                      child: _BrandTile(
                        brand: brand,
                        onTap: () => context.push(
                          '/search',
                          extra: FilterState(brand: brand),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      t.exploreAllCars,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: Text(t.viewAllArrow),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Consumer<DiscoveryProvider>(
            builder: (context, provider, _) {
              if (provider.loading && provider.cars.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final cars = provider.cars;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final car = cars[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: CarCard(
                        car: car,
                        onBookNow: () => context.push('/car/${car.id}'),
                        onTap: () => context.push('/car/${car.id}'),
                        isFavorite: provider.isFavorite(car.id),
                        onFavoriteToggle: provider.userId != null
                            ? () => provider.toggleFavorite(car.id)
                            : null,
                      ),
                    );
                  },
                  childCount: cars.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final provider = context.read<DiscoveryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(current: provider.filters),
    );
    if (result != null && context.mounted) {
      if (result.isEmpty) {
        provider.clearFilters();
      } else {
        provider.applyFilters(result);
      }
    }
  }
}

class _AppBarPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color onHero;

  const _AppBarPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onHero,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final heroText = onHero;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colorScheme.secondary : heroText,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colorScheme.secondary : heroText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        onPressed: onTap,
      ),
    );
  }
}

class _FilterIconChip extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterIconChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(Icons.tune, size: 18, color: colorScheme.primary),
      label: const Text(''),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: colorScheme.surfaceContainerHighest,
      onPressed: onTap,
    );
  }
}

class _BrandTile extends StatelessWidget {
  final String brand;
  final VoidCallback onTap;

  const _BrandTile({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
            child: Text(
              brand[0],
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            brand,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
