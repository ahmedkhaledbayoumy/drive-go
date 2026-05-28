import 'package:drive_go/features/discovery/models/filter_state.dart';
import 'package:drive_go/l10n/app_localizations.dart';
import 'package:drive_go/models/enums.dart';
import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterState current;

  const FilterBottomSheet({super.key, required this.current});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const _brands = [
    'Toyota',
    'BMW',
    'Mercedes',
    'Hyundai',
    'KIA',
    'Ford',
    'Nissan',
    'Honda',
  ];

  static const _cities = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Hurghada',
    'Sharm El Sheikh',
    'Luxor',
  ];

  static const _classes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Truck',
  ];

  late String? _brand;
  late String? _city;
  late String? _carClass;
  late String? _color;
  late RangeValues _priceRange;
  late Transmission? _transmission;
  late FuelType? _fuelType;
  late bool _availableOnly;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _brand = c.brand;
    _city = c.city;
    _carClass = c.carClass;
    _color = c.color;
    _priceRange = RangeValues(c.minPrice, c.maxPrice);
    _transmission = c.transmission;
    _fuelType = c.fuelType;
    _availableOnly = c.availableOnly;
    _modelController = TextEditingController(text: c.model ?? '');
  }

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  FilterState get _state {
    final modelText = _modelController.text.trim();
    return FilterState(
      brand: _brand,
      model: modelText.isEmpty ? null : modelText,
      city: _city,
      carClass: _carClass,
      color: _color,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      transmission: _transmission,
      fuelType: _fuelType,
      availableOnly: _availableOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    t.filters,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(theme, colorScheme, t.brand),
                    _dropdown(
                      context: context,
                      value: _brand,
                      hint: t.anyBrand,
                      items: _brands,
                      onChanged: (v) => setState(() => _brand = v),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(theme, colorScheme, t.model),
                    TextField(
                      controller: _modelController,
                      decoration: InputDecoration(hintText: t.model),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(theme, colorScheme, t.city),
                    _dropdown(
                      context: context,
                      value: _city,
                      hint: t.anyCity,
                      items: _cities,
                      onChanged: (v) => setState(() => _city = v),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(theme, colorScheme, t.carClass),
                    _dropdown(
                      context: context,
                      value: _carClass,
                      hint: t.anyClass,
                      items: _classes,
                      onChanged: (v) => setState(() => _carClass = v),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(
                      theme,
                      colorScheme,
                      t.priceRangeSheetLabel(
                        _priceRange.start.round(),
                        _priceRange.end.round(),
                      ),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: FilterState.defaultMinPrice,
                      max: FilterState.defaultMaxPrice,
                      divisions: 100,
                      activeColor: colorScheme.primary,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel(theme, colorScheme, t.transmission),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoiceChip(
                          context: context,
                          label: t.manual,
                          selected: _transmission == Transmission.manual,
                          onSelected: (selected) => setState(() {
                            _transmission =
                                selected ? Transmission.manual : null;
                          }),
                        ),
                        _buildChoiceChip(
                          context: context,
                          label: t.automatic,
                          selected: _transmission == Transmission.automatic,
                          onSelected: (selected) => setState(() {
                            _transmission =
                                selected ? Transmission.automatic : null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(theme, colorScheme, t.fuel),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FuelType.values.map((fuel) {
                        return _buildChoiceChip(
                          context: context,
                          label: _fuelLabel(t, fuel),
                          selected: _fuelType == fuel,
                          onSelected: (selected) => setState(() {
                            _fuelType = selected ? fuel : null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(theme, colorScheme, t.color),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions(t).map((option) {
                        return _buildChoiceChip(
                          context: context,
                          label: option.label,
                          selected: _color == option.value,
                          onSelected: (selected) => setState(() {
                            _color = selected ? option.value : null;
                          }),
                        );
                      }).toList(),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        t.availableOnly,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      value: _availableOnly,
                      activeThumbColor: colorScheme.primary,
                      onChanged: (v) => setState(() => _availableOnly = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const FilterState(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(t.clearAll),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _state),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(t.applyFilters),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      selected: selected,
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      onSelected: onSelected,
    );
  }

  List<({String value, String label})> _colorOptions(AppLocalizations t) {
    return [
      (value: 'White', label: t.colorWhite),
      (value: 'Black', label: t.colorBlack),
      (value: 'Silver', label: t.colorSilver),
      (value: 'Blue', label: t.colorBlue),
      (value: 'Red', label: t.colorRed),
      (value: 'Grey', label: t.colorGrey),
      (value: 'Gold', label: t.colorGold),
    ];
  }

  Widget _sectionLabel(ThemeData theme, ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _dropdown({
    required BuildContext context,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface),
          dropdownColor: colorScheme.surface,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
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
