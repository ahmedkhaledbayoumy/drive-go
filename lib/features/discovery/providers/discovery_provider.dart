import 'dart:async';

import 'package:drive_go/features/discovery/models/filter_state.dart';
import 'package:drive_go/features/discovery/services/discovery_service.dart';
import 'package:drive_go/models/models.dart';
import 'package:flutter/foundation.dart';

class DiscoveryProvider extends ChangeNotifier {
  DiscoveryProvider({this.userId}) {
    _startStream();
    if (userId != null) {
      _loadFavorites();
    }
  }

  final String? userId;

  List<Car> _cars = [];
  List<Car> _favoriteCars = [];
  bool _loading = false;
  FilterState _filters = const FilterState();
  Set<String> _favoriteIds = {};
  String _query = '';
  StreamSubscription<List<Car>>? _sub;

  List<Car> get cars => List.unmodifiable(_cars);
  List<Car> get favoriteCars => List.unmodifiable(_favoriteCars);
  bool get loading => _loading;
  FilterState get filters => _filters;
  String get query => _query;

  List<Car> get filteredCars {
    if (_query.trim().isEmpty) return List.unmodifiable(_cars);
    final q = _query.trim().toLowerCase();
    return _cars
        .where(
          (car) =>
              car.brand.toLowerCase().contains(q) ||
              car.model.toLowerCase().contains(q),
        )
        .toList();
  }

  void _startStream() {
    _sub?.cancel();
    _sub = DiscoveryService.instance.streamAvailableCars().listen(
      (cars) {
        _cars = cars;
        notifyListeners();
      },
    );
  }

  Future<void> loadCars() async {
    _loading = true;
    notifyListeners();
    try {
      _cars = await DiscoveryService.instance.fetchCars(_filters);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void applyFilters(FilterState f) {
    _sub?.cancel();
    _sub = null;
    _filters = f;
    loadCars();
  }

  void clearFilters() {
    _filters = const FilterState();
    _startStream();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> loadFavoriteCars() async {
    if (_favoriteIds.isEmpty) {
      _favoriteCars = [];
      notifyListeners();
      return;
    }
    try {
      _favoriteCars = await DiscoveryService.instance
          .fetchFavoriteCars(_favoriteIds.toList());
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String carId) async {
    if (userId == null) return;

    final wasFavorite = _favoriteIds.contains(carId);

    // Optimistic UI update
    if (wasFavorite) {
      _favoriteIds.remove(carId);
      _favoriteCars = _favoriteCars.where((c) => c.id != carId).toList();
    } else {
      _favoriteIds.add(carId);
      final car = _cars.where((c) => c.id == carId).firstOrNull;
      if (car != null) {
        _favoriteCars = [..._favoriteCars, car];
      }
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await DiscoveryService.instance.removeFavorite(userId!, carId);
      } else {
        await DiscoveryService.instance.saveFavorite(userId!, carId);
      }
      await loadFavoriteCars();
    } catch (_) {
      // Revert optimistic update on failure
      if (wasFavorite) {
        _favoriteIds.add(carId);
      } else {
        _favoriteIds.remove(carId);
      }
      notifyListeners();
      await loadFavoriteCars();
    }
  }

  Future<void> _loadFavorites() async {
    if (userId == null) return;
    try {
      final ids = await DiscoveryService.instance.fetchFavoriteIds(userId!);
      _favoriteIds = ids.toSet();
      await loadFavoriteCars();
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
