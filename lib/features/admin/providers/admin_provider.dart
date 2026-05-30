import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/models.dart';
import '../../../models/enums.dart';

class AdminStats {
  final int totalUsers;
  final int totalCars;
  final int totalBookings;
  final int pendingBookings;
  final int activeBookings;
  final int totalRevenue;
  final int pendingVerifications;

  const AdminStats({
    required this.totalUsers,
    required this.totalCars,
    required this.totalBookings,
    required this.pendingBookings,
    required this.activeBookings,
    required this.totalRevenue,
    required this.pendingVerifications,
  });
}

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  AdminStats? _stats;
  AdminStats? get stats => _stats;

  List<Profile> _users = [];
  List<Profile> get users => _users;

  List<Profile> _filteredUsers = [];
  List<Profile> get filteredUsers => _filteredUsers;

  List<Car> _cars = [];
  List<Car> get cars => _cars;

  List<Car> _filteredCars = [];
  List<Car> get filteredCars => _filteredCars;

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  String _userSearch = '';
  AccountType? _userTypeFilter;
  String _carSearch = '';
  BookingStatus? _bookingStatusFilter;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadUsers(),
        _loadCars(),
        _loadBookings(),
      ]);
      _buildStats();
    } catch (e) {
      _error = e.toString();
      debugPrint('AdminProvider.loadAll error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    final res = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));
    _users = (res as List).map((e) => Profile.fromJson(e)).toList();
    _applyUserFilters();
  }

  Future<void> _loadCars() async {
    final res = await _supabase
        .from('cars')
        .select()
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));
    _cars = (res as List).map((e) => Car.fromJson(e)).toList();
    _applyCarFilters();
  }

  Future<void> _loadBookings() async {
    final res = await _supabase
        .from('bookings')
        .select()
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));
    _bookings = (res as List).map((e) => Booking.fromJson(e)).toList();
  }

  void _buildStats() {
    final pending = _bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final active = _bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final revenue = _bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, b) => sum + b.totalPrice)
        .toInt();
    final pendingVerif =
        _users.where((u) => u.isDealership && !u.verified).length;

    _stats = AdminStats(
      totalUsers: _users.length,
      totalCars: _cars.length,
      totalBookings: _bookings.length,
      pendingBookings: pending,
      activeBookings: active,
      totalRevenue: revenue,
      pendingVerifications: pendingVerif,
    );
  }

  // ── User management ──────────────────────────────────────────

  void filterUsers({String? search, AccountType? type}) {
    if (search != null) _userSearch = search;
    if (type != null) _userTypeFilter = type;
    _applyUserFilters();
    notifyListeners();
  }

  void clearUserTypeFilter() {
    _userTypeFilter = null;
    _applyUserFilters();
    notifyListeners();
  }

  void _applyUserFilters() {
    _filteredUsers = _users.where((u) {
      final matchSearch = _userSearch.isEmpty ||
          u.fullName.toLowerCase().contains(_userSearch.toLowerCase()) ||
          u.email.toLowerCase().contains(_userSearch.toLowerCase());
      final matchType =
          _userTypeFilter == null || u.accountType == _userTypeFilter;
      return matchSearch && matchType;
    }).toList();
  }

  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
    _users.removeWhere((u) => u.id == userId);
    _applyUserFilters();
    _buildStats();
    notifyListeners();
  }

  Future<void> verifyDealership(String userId) async {
    await _supabase
        .from('profiles')
        .update({'verified': true}).eq('id', userId);
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _users[idx];
      _users[idx] = Profile(
        id: old.id,
        email: old.email,
        fullName: old.fullName,
        phone: old.phone,
        accountType: old.accountType,
        avatarUrl: old.avatarUrl,
        createdAt: old.createdAt,
        businessName: old.businessName,
        bannerUrl: old.bannerUrl,
        verified: true,
        city: old.city,
      );
    }
    _applyUserFilters();
    _buildStats();
    notifyListeners();
  }

  // ── Car management ───────────────────────────────────────────

  void filterCars({String? search}) {
    if (search != null) _carSearch = search;
    _applyCarFilters();
    notifyListeners();
  }

  void _applyCarFilters() {
    _filteredCars = _cars.where((c) {
      return _carSearch.isEmpty ||
          c.brand.toLowerCase().contains(_carSearch.toLowerCase()) ||
          c.model.toLowerCase().contains(_carSearch.toLowerCase()) ||
          c.city.toLowerCase().contains(_carSearch.toLowerCase());
    }).toList();
  }

  Future<void> deleteCar(String carId) async {
    await _supabase.from('cars').delete().eq('id', carId);
    _cars.removeWhere((c) => c.id == carId);
    _applyCarFilters();
    _buildStats();
    notifyListeners();
  }

  Future<void> updateCarStatus(String carId, CarStatus status) async {
    await _supabase
        .from('cars')
        .update({'status': status.name}).eq('id', carId);
    final idx = _cars.indexWhere((c) => c.id == carId);
    if (idx != -1) {
      final old = _cars[idx];
      _cars[idx] = Car(
        id: old.id,
        ownerId: old.ownerId,
        brand: old.brand,
        model: old.model,
        year: old.year,
        color: old.color,
        transmission: old.transmission,
        fuelType: old.fuelType,
        city: old.city,
        pricePerDay: old.pricePerDay,
        pricePerWeek: old.pricePerWeek,
        pricePerMonth: old.pricePerMonth,
        description: old.description,
        photos: old.photos,
        status: status,
        createdAt: old.createdAt,
      );
    }
    _applyCarFilters();
    notifyListeners();
  }

  // ── Booking management ───────────────────────────────────────

  void filterBookings({BookingStatus? status}) {
    _bookingStatusFilter = status;
    notifyListeners();
  }

  List<Booking> get filteredBookings {
    if (_bookingStatusFilter == null) return _bookings;
    return _bookings
        .where((b) => b.status == _bookingStatusFilter)
        .toList();
  }

  BookingStatus? get bookingStatusFilter => _bookingStatusFilter;

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _supabase
        .from('bookings')
        .update({'status': status.name}).eq('id', bookingId);
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final old = _bookings[idx];
      _bookings[idx] = Booking(
        id: old.id,
        carId: old.carId,
        customerId: old.customerId,
        ownerId: old.ownerId,
        startDate: old.startDate,
        endDate: old.endDate,
        totalPrice: old.totalPrice,
        withDriver: old.withDriver,
        pickupLocation: old.pickupLocation,
        status: status,
        paymentStatus: old.paymentStatus,
        createdAt: old.createdAt,
      );
    }
    _buildStats();
    notifyListeners();
  }
}
