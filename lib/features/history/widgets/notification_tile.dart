import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';

// ── NotificationTile ──────────────────────────────────────────────────────────
// A single row in the NotificationsScreen list.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AppNotificationItem notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: unread
            ? cs.primaryContainer.withValues(alpha: 0.25)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconBgColor(context, notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(notification.iconCodePoint,
                    fontFamily: 'MaterialIcons'),
                color: _iconColor(context, notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: tt.labelSmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (unread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _iconBgColor(BuildContext ctx, String type) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (type) {
      'bookingConfirmed' => Colors.green.withValues(alpha: 0.15),
      'bookingDeclined' => cs.errorContainer,
      'reviewPrompt' => Colors.amber.withValues(alpha: 0.2),
      'statusChange' => cs.primaryContainer,
      _ => cs.secondaryContainer,
    };
  }

  Color _iconColor(BuildContext ctx, String type) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (type) {
      'bookingConfirmed' => Colors.green.shade700,
      'bookingDeclined' => cs.error,
      'reviewPrompt' => Colors.amber.shade700,
      'statusChange' => cs.primary,
      _ => cs.secondary,
    };
  }
}

// ── NotificationBadge ─────────────────────────────────────────────────────────
//
// Drop-in replacement for an IconButton in any AppBar.
// Wraps the bell icon with a red unread-count bubble.
//
// USAGE (in any screen's AppBar — e.g. in DiscoveryScreen, HistoryScreen):
//
//   appBar: AppBar(
//     actions: [
//       NotificationBadge(
//         onTap: () => context.pushNamed('notifications'),
//       ),
//       ...
//     ],
//   ),
//
// That's it. It reads from NotificationProvider automatically.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, provider, __) {
        final count = provider.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
