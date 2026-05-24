import 'package:drive_go/models/enums.dart';

/// Immutable filter criteria for car discovery / search.
class FilterState {
  static const double defaultMinPrice = 0;
  static const double defaultMaxPrice = 5000;

  final String? brand;
  final String? city;
  final String? carClass;
  final double minPrice;
  final double maxPrice;
  final Transmission? transmission;
  final FuelType? fuelType;
  final bool availableOnly;

  const FilterState({
    this.brand,
    this.city,
    this.carClass,
    this.minPrice = defaultMinPrice,
    this.maxPrice = defaultMaxPrice,
    this.transmission,
    this.fuelType,
    this.availableOnly = false,
  });

  FilterState copyWith({
    String? brand,
    String? city,
    String? carClass,
    double? minPrice,
    double? maxPrice,
    Transmission? transmission,
    FuelType? fuelType,
    bool? availableOnly,
    bool clearBrand = false,
    bool clearCity = false,
    bool clearCarClass = false,
    bool clearTransmission = false,
    bool clearFuelType = false,
  }) {
    return FilterState(
      brand: clearBrand ? null : (brand ?? this.brand),
      city: clearCity ? null : (city ?? this.city),
      carClass: clearCarClass ? null : (carClass ?? this.carClass),
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
      city == null &&
      carClass == null &&
      minPrice == defaultMinPrice &&
      maxPrice == defaultMaxPrice &&
      transmission == null &&
      fuelType == null &&
      !availableOnly;
}
