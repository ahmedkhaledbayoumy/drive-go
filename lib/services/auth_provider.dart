import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
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
      notifyListeners();
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
      // Profile doesn't exist yet — created during signup.
    }
  }

  void enterAsGuest() {
    _state = AppAuthState.guest;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_state == AppAuthState.authenticated) {
      await _supabase.auth.signOut();
    }
    _state = AppAuthState.unauthenticated;
    _currentProfile = null;
    notifyListeners();
  }

  /// Sign in with email + password. Throws AuthException on failure.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up + create profile row in one flow.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required AccountType accountType,
    String? phone,
    String? businessName,
    String? city,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (res.user == null) {
      throw const AuthException('Sign up failed');
    }

    await _supabase.from('profiles').insert({
      'id': res.user!.id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'account_type': accountType.name,
      'business_name': businessName,
      'city': city,
      'verified': false,
    });
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update the current user's profile fields and reload from DB.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? businessName,
    String? city,
    String? avatarUrl,
  }) async {
    if (_currentProfile == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (businessName != null) updates['business_name'] = businessName;
    if (city != null) updates['city'] = city;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isEmpty) return;

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', _currentProfile!.id);

    await _loadProfile();
  }
}
