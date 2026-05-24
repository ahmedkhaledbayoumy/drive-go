import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/booking_history_card.dart';
import '../widgets/notification_tile.dart';

// ── HistoryScreen ─────────────────────────────────────────────────────────────
// Route: /history
// Shows two tabs: Active Rentals | Past Rentals
// ─────────────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    if (auth.currentProfile == null) return;
    context.read<HistoryProvider>().loadBookings(auth.currentProfile!.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        centerTitle: false,
        actions: [
          NotificationBadge(
            onTap: () => context.push('/notifications'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
        ),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == HistoryStatus.error) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Something went wrong.',
              onRetry: _load,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Active ─────────────────────────────────────────────
              _BookingList(
                bookings: provider.activeBookings,
                emptyMessage: 'No active rentals',
                emptySubtitle: 'Browse cars to book your next trip.',
                emptyIcon: Icons.car_rental_outlined,
                onEmptyAction: () => context.go('/'),
                onRentAgain: null, // Active bookings don't show Rent Again
                onLeaveReview: null,
              ),

              // ── Tab 2: Past ───────────────────────────────────────────────
              _BookingList(
                bookings: provider.pastBookings,
                emptyMessage: 'No past rentals yet',
                emptySubtitle: 'Your rental history will appear here.',
                emptyIcon: Icons.history_outlined,
                onRentAgain: (booking) =>
                    context.push('/car/${booking.carId}'),
                onLeaveReview: (booking) => context.push('/review/${booking.id}'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.onEmptyAction,
    required this.onRentAgain,
    required this.onLeaveReview,
  });

  final List<BookingSummary> bookings;
  final String emptyMessage;
  final String emptySubtitle;
  final IconData emptyIcon;
  final VoidCallback? onEmptyAction;
  final void Function(BookingSummary)? onRentAgain;
  final void Function(BookingSummary)? onLeaveReview;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subtitle: emptySubtitle,
        onAction: onEmptyAction,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        if (auth.currentProfile != null) {
          await context
              .read<HistoryProvider>()
              .loadBookings(auth.currentProfile!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingHistoryCard(
            booking: booking,
            onViewDetails: () => context.push('/booking/${booking.id}'),
            onRentAgain:
                onRentAgain != null ? () => onRentAgain!(booking) : null,
            onLeaveReview: (onLeaveReview != null && booking.canReview)
                ? () => onLeaveReview!(booking)
                : null,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String subtitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: const Text('Try Again'), // fallback or hardcoded
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Failed to load history'),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
