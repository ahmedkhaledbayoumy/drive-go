import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/models.dart';
import '../../../models/enums.dart';
// V5 NotificationService — all notification inserts go through here
// so they appear in V5's history/notifications screens automatically
import '../../history/services/notification_service.dart';

// ══════════════════════════════════════════════════════════════
// BOOKING STATUS STATE MACHINE
// ══════════════════════════════════════════════════════════════
class BookingStateMachine {
  static const Map<BookingStatus, Set<BookingStatus>> _transitions = {
    BookingStatus.pending:   {BookingStatus.confirmed, BookingStatus.declined, BookingStatus.cancelled},
    BookingStatus.confirmed: {BookingStatus.completed, BookingStatus.cancelled},
    BookingStatus.declined:  {},
    BookingStatus.completed: {},
    BookingStatus.cancelled: {},
  };

  static void assertTransition(BookingStatus from, BookingStatus to) {
    if (!(_transitions[from]?.contains(to) ?? false)) {
      throw StateError('Invalid booking transition: ${from.name} → ${to.name}');
    }
  }
}

// ══════════════════════════════════════════════════════════════
// BOOKING PROVIDER
// ══════════════════════════════════════════════════════════════
class BookingProvider extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  Booking?      _booking;
  Profile?      _ownerProfile;
  Profile?      _customerProfile;
  Car?          _car;
  List<ChatMessage> _messages = [];
  bool          _isLoading = false;
  String?       _error;

  Booking?          get booking         => _booking;
  Profile?          get ownerProfile    => _ownerProfile;
  Profile?          get customerProfile => _customerProfile;
  Car?              get car             => _car;
  List<ChatMessage> get messages        => List.unmodifiable(_messages);
  bool              get isLoading       => _isLoading;
  String?           get error           => _error;

  StreamSubscription<List<Map<String, dynamic>>>? _bookingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _chatSub;

  // ════════════════════════════════════════
  // READ — load booking + related data
  // ════════════════════════════════════════
  Future<void> loadBooking(String bookingId) async {
    _setLoading(true);
    try {
      final bData = await _db
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();
      _booking = Booking.fromJson(bData);

      final oData = await _db
          .from('profiles')
          .select()
          .eq('id', _booking!.ownerId)
          .single();
      _ownerProfile = Profile.fromJson(oData);

      final cData = await _db
          .from('profiles')
          .select()
          .eq('id', _booking!.customerId)
          .single();
      _customerProfile = Profile.fromJson(cData);

      final carData = await _db
          .from('cars')
          .select()
          .eq('id', _booking!.carId)
          .single();
      _car = Car.fromJson(carData);

      notifyListeners();
      _subscribeToBooking(bookingId);
      _subscribeToChat(bookingId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ════════════════════════════════════════
  // WRITE — create booking
  // ════════════════════════════════════════
  Future<Booking?> createBooking({
    required String carId,
    required String customerId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    required bool withDriver,
    String? pickupLocation,
  }) async {
    _setLoading(true);
    try {
      // 1. INSERT booking row
      final data = await _db.from('bookings').insert({
        'car_id':          carId,
        'customer_id':     customerId,
        'owner_id':        ownerId,
        'start_date':      startDate.toIso8601String(),
        'end_date':        endDate.toIso8601String(),
        'total_price':     totalPrice,
        'with_driver':     withDriver,
        'pickup_location': pickupLocation,
        'status':          BookingStatus.pending.name,
        'payment_status':  PaymentStatus.pending.name,
      }).select().single();

      // 2. UPDATE car status → pendingConfirmation
      await _db
          .from('cars')
          .update({'status': CarStatus.pendingConfirmation.name})
          .eq('id', carId);

      // 3. Fetch car title for notification
      final carData = await _db
          .from('cars')
          .select('brand, model, year')
          .eq('id', carId)
          .single();
      final carTitle =
          '${carData['brand']} ${carData['model']} ${carData['year']}';

      // 4. Notify owner via V5 NotificationService
      await NotificationService.newBookingRequest(
        ownerId:   ownerId,
        bookingId: data['id'] as String,
        carTitle:  carTitle,
      );

      _booking = Booking.fromJson(data);
      notifyListeners();
      return _booking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ════════════════════════════════════════
  // WRITE — status transition
  // ════════════════════════════════════════
  Future<bool> transitionStatus(BookingStatus newStatus) async {
    final current = _booking;
    if (current == null) return false;
    BookingStateMachine.assertTransition(current.status, newStatus);
    _setLoading(true);

    try {
      // 1. UPDATE booking status
      await _db
          .from('bookings')
          .update({'status': newStatus.name})
          .eq('id', current.id);

      final carTitle = _car != null
          ? '${_car!.brand} ${_car!.model} ${_car!.year}'
          : 'your car';

      final ownerAccountType =
          _ownerProfile?.accountType.name ?? 'individual';

      switch (newStatus) {
        case BookingStatus.confirmed:
          // UPDATE car → booked
          await _db.from('cars')
              .update({'status': CarStatus.booked.name})
              .eq('id', current.carId);
          // Notify customer via V5 NotificationService
          await NotificationService.bookingConfirmed(
            customerId: current.customerId,
            bookingId:  current.id,
            carTitle:   carTitle,
          );
          break;

        case BookingStatus.declined:
          // UPDATE car → available
          await _db.from('cars')
              .update({'status': CarStatus.available.name})
              .eq('id', current.carId);
          // Notify customer via V5 NotificationService
          await NotificationService.bookingCancelled(
            targetUserId: current.customerId,
            bookingId:    current.id,
            carTitle:     carTitle,
          );
          break;

        case BookingStatus.cancelled:
          // UPDATE car → available
          await _db.from('cars')
              .update({'status': CarStatus.available.name})
              .eq('id', current.carId);
          // Notify the other party
          final targetId = current.customerId;
          await NotificationService.bookingCancelled(
            targetUserId: targetId,
            bookingId:    current.id,
            carTitle:     carTitle,
          );
          break;

        case BookingStatus.completed:
          // UPDATE car → available
          await _db.from('cars')
              .update({'status': CarStatus.available.name})
              .eq('id', current.carId);
          // Notify customer + trigger review prompt if dealership
          await NotificationService.bookingCompleted(
            customerId:       current.customerId,
            bookingId:        current.id,
            carTitle:         carTitle,
            ownerAccountType: ownerAccountType,
            ownerId:          current.ownerId,
            dealershipName:   _ownerProfile?.businessName,
          );
          break;

        default:
          break;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ════════════════════════════════════════
  // WRITE — mock payment
  // ════════════════════════════════════════
  Future<bool> processMockPayment() async {
    final current = _booking;
    if (current == null) return false;
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    try {
      // UPDATE bookings.payment_status = paid
      await _db
          .from('bookings')
          .update({'payment_status': PaymentStatus.paid.name})
          .eq('id', current.id);

      final carTitle = _car != null
          ? '${_car!.brand} ${_car!.model} ${_car!.year}'
          : 'your car';

      // Notify owner via V5 NotificationService
      await NotificationService.bookingActive(
        ownerId:   current.ownerId,
        bookingId: current.id,
        carTitle:  carTitle,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ════════════════════════════════════════
  // WRITE — send chat message
  // ════════════════════════════════════════
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      await _db.from('chat_messages').insert({
        'booking_id': bookingId,
        'sender_id':  senderId,
        'text':       text.trim(),
        'read':       false,
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ════════════════════════════════════════
  // WRITE — mark messages read
  // ════════════════════════════════════════
  Future<void> markMessagesRead(String bookingId, String userId) async {
    try {
      await _db
          .from('chat_messages')
          .update({'read': true})
          .eq('booking_id', bookingId)
          .neq('sender_id', userId)
          .eq('read', false);
    } catch (_) {}
  }

  // ════════════════════════════════════════
  // REALTIME
  // ════════════════════════════════════════
  void _subscribeToBooking(String bookingId) {
    _bookingSub?.cancel();
    _bookingSub = _db
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .listen((rows) {
          if (rows.isNotEmpty) {
            _booking = Booking.fromJson(rows.first);
            notifyListeners();
          }
        });
  }

  void _subscribeToChat(String bookingId) {
    _chatSub?.cancel();
    _chatSub = _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .listen((rows) {
          final sorted = rows.toList()
            ..sort((a, b) => (a['created_at'] as String)
                .compareTo(b['created_at'] as String));
          _messages = sorted.map(ChatMessage.fromJson).toList();
          notifyListeners();
        });
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}
