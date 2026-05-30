import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── HistoryProvider ───────────────────────────────────────────────────────────
//
// Manages the customer's booking history and review submission.
//
// SETUP: Register in main.dart alongside your other providers (see guide).
// ─────────────────────────────────────────────────────────────────────────────

enum HistoryStatus { initial, loading, loaded, error }

/// Lightweight booking summary used inside this vertical only.
/// The full Booking model lives in models/models.dart — this wraps the
/// Supabase JSON with the joined car + owner data.
class BookingSummary {
  final String id;
  final String carId;
  final String ownerId;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String status; // pending | confirmed | active | completed | cancelled
  final String paymentStatus; // unpaid | paid
  final double totalPrice;
  final bool withDriver;
  final bool reviewSubmitted;
  final DateTime createdAt;

  // Joined fields ─ may be null if DB query omits them
  final String? carMake;
  final String? carModel;
  final int? carYear;
  final String? carImageUrl;
  final double? carDailyPrice;
  final String? ownerName;
  final String? ownerPhotoUrl;
  final String? ownerAccountType; // 'individual' | 'dealership'
  final String? dealershipName;

  const BookingSummary({
    required this.id,
    required this.carId,
    required this.ownerId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    required this.withDriver,
    required this.reviewSubmitted,
    required this.createdAt,
    this.carMake,
    this.carModel,
    this.carYear,
    this.carImageUrl,
    this.carDailyPrice,
    this.ownerName,
    this.ownerPhotoUrl,
    this.ownerAccountType,
    this.dealershipName,
  });

  String get carTitle =>
      '${carMake ?? ''} ${carModel ?? ''} ${carYear ?? ''}'.trim();

  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'active';

  bool get isPast => status == 'completed' || status == 'cancelled' || status == 'declined';

  bool get canReview =>
      status == 'completed' &&
      !reviewSubmitted &&
      ownerAccountType == 'dealership';

  int get rentalDays => endDate.difference(startDate).inDays.clamp(1, 9999);

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    final car = json['car'] as Map<String, dynamic>?;
    final owner = car?['owner'] as Map<String, dynamic>?;
    final images = car?['photos'] as List?;

    return BookingSummary(
      id: json['id'] as String,
      carId: json['car_id'] as String,
      ownerId: json['owner_id'] as String,
      customerId: json['customer_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      pickupLocation: json['pickup_location'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      withDriver: json['with_driver'] as bool? ?? false,
      reviewSubmitted: (json['reviews'] as List?)?.isNotEmpty ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      carMake: car?['brand'] as String?,
      carModel: car?['model'] as String?,
      carYear: car?['year'] as int?,
      carImageUrl: (images != null && images.isNotEmpty)
          ? images.first as String?
          : null,
      carDailyPrice: (car?['price_per_day'] as num?)?.toDouble(),
      ownerName: owner?['full_name'] as String?,
      ownerPhotoUrl: owner?['avatar_url'] as String?,
      ownerAccountType: owner?['account_type'] as String?,
      dealershipName: owner?['business_name'] as String?,
    );
  }

  BookingSummary copyWith({bool? reviewSubmitted}) => BookingSummary(
        id: id,
        carId: carId,
        ownerId: ownerId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        pickupLocation: pickupLocation,
        status: status,
        paymentStatus: paymentStatus,
        totalPrice: totalPrice,
        withDriver: withDriver,
        reviewSubmitted: reviewSubmitted ?? this.reviewSubmitted,
        createdAt: createdAt,
        carMake: carMake,
        carModel: carModel,
        carYear: carYear,
        carImageUrl: carImageUrl,
        carDailyPrice: carDailyPrice,
        ownerName: ownerName,
        ownerPhotoUrl: ownerPhotoUrl,
        ownerAccountType: ownerAccountType,
        dealershipName: dealershipName,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class HistoryProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<BookingSummary> _bookings = [];
  HistoryStatus _status = HistoryStatus.initial;
  String? _errorMessage;

  List<BookingSummary> get allBookings => _bookings;
  List<BookingSummary> get activeBookings =>
      _bookings.where((b) => b.isActive).toList();
  List<BookingSummary> get pastBookings =>
      _bookings.where((b) => b.isPast).toList();

  HistoryStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HistoryStatus.loading;

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Fetches all bookings for [customerId], newest first.
  /// Each booking includes joined car data and the car owner's profile.
  Future<void> loadBookings(String customerId) async {
    _status = HistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Adjust the foreign-key hint (cars_owner_id_fkey) if your schema
      // names it differently — check supabase/schema.sql → cars table.
      final response = await _client.from('bookings').select('''
            id, car_id, owner_id, customer_id,
            start_date, end_date, pickup_location,
            status, payment_status, total_price,
            with_driver, created_at,
            reviews (id),
            car:cars (
              brand, model, year, price_per_day, photos,
              owner:profiles!cars_owner_id_fkey (
                full_name, avatar_url, account_type, business_name
              )
            )
          ''').eq('customer_id', customerId).order('created_at', ascending: false);

      _bookings = (response as List)
          .map((row) => BookingSummary.fromJson(row as Map<String, dynamic>))
          .toList();
      _status = HistoryStatus.loaded;
    } catch (e) {
      _status = HistoryStatus.error;
      _errorMessage = e.toString();
      debugPrint('[HistoryProvider] loadBookings error: $e');
    }
    notifyListeners();
  }

  // ── Review ────────────────────────────────────────────────────────────────

  /// Inserts a review row and marks the booking as reviewed locally.
  /// Returns true on success.
  Future<bool> submitReview({
    required String bookingId,
    required String customerId,
    required String dealershipId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _client.from('reviews').insert({
        'booking_id': bookingId,
        'customer_id': customerId,
        'dealership_id': dealershipId,
        'rating': rating.toInt(),
        'comment': comment.trim(),
      });

      // Flip the local flag so the UI updates without a full reload.
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _bookings[idx] = _bookings[idx].copyWith(reviewSubmitted: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[HistoryProvider] submitReview error: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  BookingSummary? findById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void reset() {
    _bookings = [];
    _status = HistoryStatus.initial;
    _errorMessage = null;
  }
}
