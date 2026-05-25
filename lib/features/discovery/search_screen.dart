import 'package:drive_go/features/discovery/models/filter_state.dart';
import 'package:drive_go/features/discovery/providers/discovery_provider.dart';
import 'package:drive_go/features/discovery/widgets/filter_bottom_sheet.dart';
import 'package:drive_go/features/discovery/widgets/main_bottom_nav.dart';
import 'package:drive_go/l10n/app_localizations.dart';
import 'package:drive_go/models/enums.dart';
import 'package:drive_go/widgets/car_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  final FilterState? initialFilters;

  const SearchScreen({super.key, this.initialFilters});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DiscoveryProvider>().applyFilters(widget.initialFilters!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          autofocus: widget.initialFilters == null,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: t.searchDreamCar,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          onChanged: context.read<DiscoveryProvider>().setQuery,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: colorScheme.onSurface),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!provider.filters.isEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _activeFilterChips(context, provider, t),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      t.recommendForYou,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(t.viewAll),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.filteredCars.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t.noResults,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: provider.filteredCars.length,
                            itemBuilder: (context, index) {
                              final car = provider.filteredCars[index];
                              return CarCard(
                                car: car,
                                onBookNow: () =>
                                    context.push('/car/${car.id}'),
                                onTap: () => context.push('/car/${car.id}'),
                                isFavorite: provider.isFavorite(car.id),
                                onFavoriteToggle: provider.userId != null
                                    ? () => provider.toggleFavorite(car.id)
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }

  List<Widget> _activeFilterChips(
    BuildContext context,
    DiscoveryProvider provider,
    AppLocalizations t,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final filters = provider.filters;
    final chips = <Widget>[];

    void addChip(String label, VoidCallback onClear) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(label),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: onClear,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    }

    if (filters.brand != null) {
      addChip(filters.brand!, () {
        provider.applyFilters(filters.copyWith(clearBrand: true));
      });
    }
    if (filters.model != null) {
      addChip(filters.model!, () {
        provider.applyFilters(filters.copyWith(clearModel: true));
      });
    }
    if (filters.city != null) {
      addChip(filters.city!, () {
        provider.applyFilters(filters.copyWith(clearCity: true));
      });
    }
    if (filters.color != null) {
      addChip(filters.color!, () {
        provider.applyFilters(filters.copyWith(clearColor: true));
      });
    }
    if (filters.carClass != null) {
      addChip(filters.carClass!, () {
        provider.applyFilters(filters.copyWith(clearCarClass: true));
      });
    }
    if (filters.transmission != null) {
      addChip(
        _transmissionLabel(t, filters.transmission!),
        () {
          provider.applyFilters(filters.copyWith(clearTransmission: true));
        },
      );
    }
    if (filters.fuelType != null) {
      addChip(
        _fuelLabel(t, filters.fuelType!),
        () {
          provider.applyFilters(filters.copyWith(clearFuelType: true));
        },
      );
    }
    if (filters.availableOnly) {
      addChip(t.availableOnly, () {
        provider.applyFilters(filters.copyWith(availableOnly: false));
      });
    }
    if (filters.minPrice > FilterState.defaultMinPrice ||
        filters.maxPrice < FilterState.defaultMaxPrice) {
      addChip(
        t.priceRangeLabel(
          filters.minPrice.round(),
          filters.maxPrice.round(),
        ),
        () {
          provider.applyFilters(
            filters.copyWith(
              minPrice: FilterState.defaultMinPrice,
              maxPrice: FilterState.defaultMaxPrice,
            ),
          );
        },
      );
    }

    return chips;
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

  String _transmissionLabel(AppLocalizations t, Transmission transmission) {
    return transmission == Transmission.manual ? t.manual : t.automatic;
  }

  String _fuelLabel(AppLocalizations t, FuelType fuel) {
    return switch (fuel) {
      FuelType.petrol => t.petrol,
      FuelType.diesel => t.diesel,
      FuelType.hybrid => t.hybrid,
      FuelType.electric => t.electric,
    };
  }
}
