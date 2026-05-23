import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Supabase calls related to owner (Profile) data shown in V3.
class OwnerService {
  OwnerService._();
  static final OwnerService instance = OwnerService._();

  final SupabaseClient _db = Supabase.instance.client;

  /// Fetches a public profile by [ownerId].
  Future<Profile> fetchProfile(String ownerId) async {
    final row =
        await _db.from('profiles').select().eq('id', ownerId).single();
    return Profile.fromJson(row);
  }

  /// Returns all reviews left for a dealership.
  Future<List<Review>> fetchDealershipReviews(String dealershipId) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('dealership_id', dealershipId)
        .order('created_at', ascending: false);
    return rows.map((r) => Review.fromJson(r)).toList();
  }

  /// Updates [bannerUrl] on the authenticated user's profile.
  Future<void> saveBannerUrl(String userId, String bannerUrl) async {
    await _db
        .from('profiles')
        .update({'banner_url': bannerUrl}).eq('id', userId);
  }
}