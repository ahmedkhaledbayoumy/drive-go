import 'package:drive_go/features/discovery/models/filter_state.dart';
import 'package:drive_go/models/enums.dart';
import 'package:drive_go/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase calls for marketplace discovery, search, and favorites.
class DiscoveryService {
  DiscoveryService._();

  static final DiscoveryService instance = DiscoveryService._();

  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Car>> fetchCars(FilterState filters) async {
    var query = _db.from('cars').select();

    if (filters.brand != null) {
      query = query.eq('brand', filters.brand!);
    }
    if (filters.city != null) {
      query = query.eq('city', filters.city!);
    }
    if (filters.model != null) {
      query = query.eq('model', filters.model!);
    }
    if (filters.color != null) {
      query = query.eq('color', filters.color!);
    }
    if (filters.carClass != null) {
      query = query.eq('car_class', filters.carClass!);
    }
    if (filters.transmission != null) {
      query = query.eq('transmission', filters.transmission!.name);
    }
    if (filters.fuelType != null) {
      query = query.eq('fuel_type', filters.fuelType!.name);
    }
    query = query
        .gte('price_per_day', filters.minPrice)
        .lte('price_per_day', filters.maxPrice);
    if (filters.availableOnly) {
      query = query.eq('status', CarStatus.available.name);
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Car.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Car>> streamAvailableCars() {
    return _db
        .from('cars')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map((row) => Car.fromJson(row)).toList(),
        );
  }

  Future<List<String>> fetchFavoriteIds(String userId) async {
    final rows = await _db
        .from('saved_cars')
        .select('car_id')
        .eq('user_id', userId);
    return (rows as List)
        .map((row) => (row as Map<String, dynamic>)['car_id'] as String)
        .toList();
  }

  Future<List<Car>> fetchFavoriteCars(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _db.from('cars').select().inFilter('id', ids);
    return (rows as List)
        .map((row) => Car.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorite(String userId, String carId) async {
    await _db.from('saved_cars').insert({
      'user_id': userId,
      'car_id': carId,
    });
  }

  Future<void> removeFavorite(String userId, String carId) async {
    await _db
        .from('saved_cars')
        .delete()
        .eq('user_id', userId)
        .eq('car_id', carId);
  }
}
