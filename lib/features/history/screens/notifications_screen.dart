import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

// ── NotificationsScreen ───────────────────────────────────────────────────────
// Route: /notifications
// Displays all notifications for the current user, newest first.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh when screen opens so the list is always fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentProfile != null) {
        context.read<NotificationProvider>().refresh(auth.currentProfile!.id);
      }
    });
  }

  String get _userId =>
      context.read<AuthProvider>().currentProfile?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (!provider.hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => provider.markAllAsRead(_userId),
                child: Text(
                  'Mark all read',
                  style: TextStyle(color: cs.primary),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return _EmptyNotifications();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(_userId),
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 70,
                color: cs.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                return NotificationTile(
                  notification: notif,
                  onTap: () {
                    provider.markAsRead(notif.id);
                    _handleNotificationTap(context, notif);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Navigates to the relevant screen based on notification type and referenceId.
  void _handleNotificationTap(
      BuildContext context, AppNotificationItem notif) {
    final ref = notif.referenceId;
    if (ref == null) return;

    switch (notif.type) {
      case 'bookingRequest':
      case 'bookingConfirmed':
      case 'bookingDeclined':
        context.push('/booking/$ref');
        break;
      case 'reviewPrompt':
        context.push('/review/$ref');
        break;
      case 'statusChange':
        if (notif.title.contains('Listing')) {
          context.push('/car/$ref');
        } else {
          context.push('/booking/$ref');
        }
        break;
      default:
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 44,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'You have no notifications yet.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
