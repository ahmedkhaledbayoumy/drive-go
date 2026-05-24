import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ── NotificationService ──────────────────────────────────────────────────────
///
/// Static helpers that V3 (listings) and V4 (booking/chat/payment) call to
/// write rows into the `notifications` table.  V5's [NotificationProvider]
/// then streams those rows in real-time for the current user.
///
/// INTEGRATION NOTES FOR V3 & V4:
///   1. Import this file:
///        import 'package:drive_go/features/history/services/notification_service.dart';
///   2. Call the appropriate helper — every call is fire-and-forget (errors are
///      logged but never rethrow so they cannot break your flow).
///   3. See individual method docs for exactly when to call each one.
///
/// Notification types (stored in `notifications.type` column):
///   'booking_request'   – owner receives when customer submits a booking
///   'booking_confirmed' – customer receives when owner confirms
///   'booking_cancelled' – either party receives on cancellation
///   'booking_completed' – customer receives when rental finishes
///   'review_prompt'     – customer receives after a Dealership rental completes
///   'status_change'     – owner receives when a listing status changes
/// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final _client = Supabase.instance.client;

  // ── Core insert ─────────────────────────────────────────────────────────────

  /// Low-level insert.  Prefer the named helpers below.
  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? referenceId, // booking id, car id, etc. used for deep-linking
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        if (referenceId != null) 'related_id': referenceId,
        'read': false,
      });
    } catch (e) {
      // Notifications are non-critical — log but never rethrow.
      debugPrint('[NotificationService] send() failed: $e');
    }
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────

  /// V4 → call this immediately after inserting a booking row (status=pending).
  /// Notifies the *owner* that a customer wants to rent their car.
  static Future<void> newBookingRequest({
    required String ownerId,
    required String bookingId,
    required String carTitle, // e.g. "Toyota Corolla 2022"
  }) =>
      send(
        userId: ownerId,
        title: 'New Booking Request',
        body: 'Someone wants to rent your $carTitle.',
        type: 'bookingRequest',
        referenceId: bookingId,
      );

  /// V4 → call this when the owner changes booking status to 'confirmed'.
  /// Notifies the *customer* their booking was accepted.
  static Future<void> bookingConfirmed({
    required String customerId,
    required String bookingId,
    required String carTitle,
  }) =>
      send(
        userId: customerId,
        title: 'Booking Confirmed ✓',
        body: 'Your rental of $carTitle is confirmed. Have a great trip!',
        type: 'bookingConfirmed',
        referenceId: bookingId,
      );

  /// V4 → call this when either party cancels.
  /// Pass the *other* party's userId as [targetUserId].
  static Future<void> bookingCancelled({
    required String targetUserId,
    required String bookingId,
    required String carTitle,
  }) =>
      send(
        userId: targetUserId,
        title: 'Booking Cancelled',
        body: 'The booking for $carTitle has been cancelled.',
        type: 'bookingDeclined',
        referenceId: bookingId,
      );

  /// V4 → call this when payment_status flips to 'paid' AND status = 'active'.
  static Future<void> bookingActive({
    required String ownerId,
    required String bookingId,
    required String carTitle,
  }) =>
      send(
        userId: ownerId,
        title: 'Payment Received',
        body: 'Payment confirmed. $carTitle rental is now active.',
        type: 'bookingConfirmed',
        referenceId: bookingId,
      );

  /// V4 → call this when status transitions to 'completed'.
  /// Also triggers a review prompt if the owner is a Dealership.
  ///
  /// [ownerAccountType] should be the owner's `profiles.account_type` value.
  /// Pass 'dealership' to trigger the review prompt.
  static Future<void> bookingCompleted({
    required String customerId,
    required String bookingId,
    required String carTitle,
    required String ownerAccountType,
    required String ownerId,
    String? dealershipName,
  }) async {
    await send(
      userId: customerId,
      title: 'Rental Completed',
      body: 'Your trip in $carTitle is complete. Thanks for using Drive Go!',
      type: 'statusChange',
      referenceId: bookingId,
    );

    if (ownerAccountType == 'dealership') {
      await reviewPrompt(
        customerId: customerId,
        bookingId: bookingId,
        dealershipName: dealershipName ?? 'the dealership',
      );
    }
  }

  /// V5 internal — called by [bookingCompleted] when owner is a Dealership.
  /// Can also be called standalone if needed.
  static Future<void> reviewPrompt({
    required String customerId,
    required String bookingId,
    required String dealershipName,
  }) =>
      send(
        userId: customerId,
        title: 'How was your rental?',
        body: 'Leave a review for $dealershipName and help other drivers.',
        type: 'reviewPrompt',
        referenceId: bookingId,
      );

  /// V3 → call this when a car listing status changes (available/pending/booked).
  static Future<void> listingStatusChanged({
    required String ownerId,
    required String carId,
    required String carTitle,
    required String newStatus,
  }) =>
      send(
        userId: ownerId,
        title: 'Listing Update',
        body: 'Your $carTitle listing status changed to $newStatus.',
        type: 'statusChange',
        referenceId: carId,
      );
}
