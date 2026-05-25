import 'package:drive_go/models/enums.dart';

/// Immutable filter criteria for car discovery / search.
class FilterState {
  static const double defaultMinPrice = 0;
  static const double defaultMaxPrice = 5000;

  final String? brand;
  final String? model;
  final String? city;
  final String? carClass;
  final String? color;
  final double minPrice;
  final double maxPrice;
  final Transmission? transmission;
  final FuelType? fuelType;
  final bool availableOnly;

  const FilterState({
    this.brand,
    this.model,
    this.city,
    this.carClass,
    this.color,
    this.minPrice = defaultMinPrice,
    this.maxPrice = defaultMaxPrice,
    this.transmission,
    this.fuelType,
    this.availableOnly = false,
  });

  FilterState copyWith({
    String? brand,
    String? model,
    String? city,
    String? carClass,
    String? color,
    double? minPrice,
    double? maxPrice,
    Transmission? transmission,
    FuelType? fuelType,
    bool? availableOnly,
    bool clearBrand = false,
    bool clearModel = false,
    bool clearCity = false,
    bool clearCarClass = false,
    bool clearColor = false,
    bool clearTransmission = false,
    bool clearFuelType = false,
  }) {
    return FilterState(
      brand: clearBrand ? null : (brand ?? this.brand),
      model: clearModel ? null : (model ?? this.model),
      city: clearCity ? null : (city ?? this.city),
      carClass: clearCarClass ? null : (carClass ?? this.carClass),
      color: clearColor ? null : (color ?? this.color),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      transmission:
          clearTransmission ? null : (transmission ?? this.transmission),
      fuelType: clearFuelType ? null : (fuelType ?? this.fuelType),
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }

  /// True when no filter differs from the default [FilterState].
  bool get isEmpty =>
      brand == null &&
      model == null &&
      city == null &&
      carClass == null &&
      color == null &&
      minPrice == defaultMinPrice &&
      maxPrice == defaultMaxPrice &&
      transmission == null &&
      fuelType == null &&
      !availableOnly;
}
