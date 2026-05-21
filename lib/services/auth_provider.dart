import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Three states the app can be in.
enum AppAuthState { unauthenticated, guest, authenticated }

/// Listens to Supabase auth and exposes the current Profile.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AppAuthState _state = AppAuthState.unauthenticated;
  AppAuthState get state => _state;

  Profile? _currentProfile;
  Profile? get currentProfile => _currentProfile;

  Session? get session => _supabase.auth.currentSession;
  User? get authUser => _supabase.auth.currentUser;

  bool get isAuthenticated => _state == AppAuthState.authenticated;
  bool get isGuest => _state == AppAuthState.guest;
  bool get isUnauthenticated => _state == AppAuthState.unauthenticated;

  AuthProvider() {
    if (_supabase.auth.currentSession != null) {
      _state = AppAuthState.authenticated;
      _loadProfile();
    }
    _supabase.auth.onAuthStateChange.listen(_handleAuthChange);
  }

  void _handleAuthChange(AuthState event) {
    if (event.session != null) {
      _state = AppAuthState.authenticated;
      _loadProfile();
    } else if (_state == AppAuthState.authenticated) {
      _state = AppAuthState.unauthenticated;
      _currentProfile = null;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();
      _currentProfile = Profile.fromJson(response);
      notifyListeners();
    } catch (_) {
      // Profile doesn't exist yet — V1 creates it during signup.
    }
  }

  void enterAsGuest() {
    _state = AppAuthState.guest;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _state = AppAuthState.unauthenticated;
    _currentProfile = null;
    notifyListeners();
  }
}
