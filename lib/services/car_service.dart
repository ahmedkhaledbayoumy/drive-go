import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/models.dart';
 
/// All Supabase calls related to the [cars] collection.
/// Covers: fetch, create, update, delete, photo uploads.
class CarService {
  CarService._();
  static final CarService instance = CarService._();
 
  final SupabaseClient _db = Supabase.instance.client;
 
  // ─── READ ───────────────────────────────────────────────────
 
  /// Returns all cars owned by [ownerId].
  Future<List<Car>> fetchOwnerCars(String ownerId) async {
    final rows = await _db
        .from('cars')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return rows.map((r) => Car.fromJson(r)).toList();
  }
 
  /// Returns a single car by [carId].
  Future<Car> fetchCar(String carId) async {
    final row = await _db.from('cars').select().eq('id', carId).single();
    return Car.fromJson(row);
  }
 
  /// Returns all cars for a given owner's public profile page.
  Future<List<Car>> fetchOwnerPublicCars(String ownerId) async {
    final rows = await _db
        .from('cars')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return rows.map((r) => Car.fromJson(r)).toList();
  }
 
  // ─── WRITE ──────────────────────────────────────────────────
 
  /// Creates a new car listing. Returns the created [Car].
  Future<Car> createCar({
    required String ownerId,
    required String brand,
    required String model,
    required int year,
    required String color,
    required Transmission transmission,
    required FuelType fuelType,
    required String city,
    required double pricePerDay,
    double? pricePerWeek,
    double? pricePerMonth,
    required String description,
    required List<String> photos,
  }) async {
    final row = await _db
        .from('cars')
        .insert({
          'owner_id': ownerId,
          'brand': brand,
          'model': model,
          'year': year,
          'color': color,
          'transmission': transmission.name,
          'fuel_type': fuelType.name,
          'city': city,
          'price_per_day': pricePerDay,
          'price_per_week': pricePerWeek,
          'price_per_month': pricePerMonth,
          'description': description,
          'photos': photos,
          'status': CarStatus.available.name,
        })
        .select()
        .single();
    return Car.fromJson(row);
  }
 
  /// Updates an existing listing. Pass only the fields to change.
  Future<Car> updateCar(String carId, Map<String, dynamic> fields) async {
    final row = await _db
        .from('cars')
        .update(fields)
        .eq('id', carId)
        .select()
        .single();
    return Car.fromJson(row);
  }
 
  /// Updates only the car's [CarStatus].
  Future<void> updateStatus(String carId, CarStatus status) async {
    await _db
        .from('cars')
        .update({'status': status.name})
        .eq('id', carId);
  }
 
  /// Deletes a listing and its photos from Storage.
  Future<void> deleteCar(Car car) async {
    // Remove photos from storage first
    for (final url in car.photos) {
      final path = _pathFromUrl(url);
      if (path != null) {
        await _db.storage.from('car-photos').remove([path]);
      }
    }
    await _db.from('cars').delete().eq('id', car.id);
  }
 
  // ─── STORAGE ────────────────────────────────────────────────
 
  /// Uploads a [File] to car-photos/{ownerId}/ and returns its public URL.
  Future<String> uploadCarPhoto(String ownerId, File file) async {
    final ext = file.path.split('.').last;
    final path =
        '$ownerId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('car-photos').upload(path, file);
    return _db.storage.from('car-photos').getPublicUrl(path);
  }
 
  /// Uploads a dealership banner and returns its public URL.
  Future<String> uploadDealershipBanner(String ownerId, File file) async {
    final ext = file.path.split('.').last;
    final path = '$ownerId/banner.$ext';
    await _db.storage
        .from('dealership-banners')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _db.storage.from('dealership-banners').getPublicUrl(path);
  }
 
  /// Deletes a single photo from car-photos by its URL.
  Future<void> deleteCarPhoto(String url) async {
    final path = _pathFromUrl(url);
    if (path != null) {
      await _db.storage.from('car-photos').remove([path]);
    }
  }
 
  // ─── HELPERS ────────────────────────────────────────────────
 
  /// Extracts the storage path from a public URL.
  /// e.g. ".../car-photos/uid/123.jpg" → "uid/123.jpg"
  String? _pathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('car-photos');
      if (idx == -1) return null;
      return segments.sublist(idx + 1).join('/');
    } catch (_) {
      return null;
    }
  }
}