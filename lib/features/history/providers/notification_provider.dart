import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── AppNotificationItem ───────────────────────────────────────────────────────
// Local model — mirrors the `notifications` table row.
// (The full AppNotification model in models/models.dart may differ slightly;
//  adjust field names to match your schema if needed.)
// ─────────────────────────────────────────────────────────────────────────────

class AppNotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  AppNotificationItem copyWith({bool? isRead}) => AppNotificationItem(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) =>
      AppNotificationItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? '',
        referenceId: json['related_id'] as String?,
        isRead: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Returns a Material icon codepoint for each notification type.
  static const Map<String, int> _typeIcons = {
    'bookingRequest': 0xe3f4, // notifications_active
    'bookingConfirmed': 0xe876, // check_circle
    'bookingDeclined': 0xe888, // cancel
    'reviewPrompt': 0xe838, // star
    'statusChange': 0xe88e, // info
  };

  int get iconCodePoint => _typeIcons[type] ?? 0xe7f4; // default: person
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<AppNotificationItem> _notifications = [];
  bool _loading = false;
  RealtimeChannel? _channel;

  List<AppNotificationItem> get notifications => _notifications;
  bool get isLoading => _loading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // ── Init / Dispose ────────────────────────────────────────────────────────

  /// Call this once when the user is authenticated.
  /// Fetches existing notifications and subscribes to new ones via Realtime.
  Future<void> init(String userId) async {
    await _fetchAll(userId);
    _subscribeRealtime(userId);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Call when the user signs out so state doesn't leak.
  void reset() {
    _channel?.unsubscribe();
    _channel = null;
    _notifications = [];
    _loading = false;
    notifyListeners();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> _fetchAll(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      _notifications = (response as List)
          .map((row) =>
              AppNotificationItem.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationProvider] _fetchAll error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _channel?.unsubscribe();

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newItem = AppNotificationItem.fromJson(payload.newRecord);
            _notifications = [newItem, ..._notifications];
            notifyListeners();
          },
        )
        .subscribe();
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  /// Marks a single notification as read in DB + locally.
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1 || _notifications[idx].isRead) return;

    // Optimistic update
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Revert on failure
      _notifications[idx] = _notifications[idx].copyWith(isRead: false);
      notifyListeners();
      debugPrint('[NotificationProvider] markAsRead error: $e');
    }
  }

  /// Marks ALL unread notifications as read.
  Future<void> markAllAsRead(String userId) async {
    if (!hasUnread) return;

    // Optimistic update
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
    } catch (e) {
      debugPrint('[NotificationProvider] markAllAsRead error: $e');
      // Re-fetch to get consistent state
      await _fetchAll(userId);
    }
  }

  // ── Public refresh ────────────────────────────────────────────────────────

  Future<void> refresh(String userId) => _fetchAll(userId);
}
