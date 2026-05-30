import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Bookings'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: admin.loadAll),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'All',
                    selected: admin.bookingStatusFilter == null,
                    color: Colors.grey[700]!,
                    onTap: () => admin.filterBookings(status: null),
                  ),
                  const SizedBox(width: 8),
                  ...BookingStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _StatusChip(
                          label: _statusLabel(s),
                          selected: admin.bookingStatusFilter == s,
                          color: _statusColor(s),
                          onTap: () => admin.filterBookings(status: s),
                        ),
                      )),
                ],
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${admin.filteredBookings.length} booking(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: admin.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32)))
                : admin.filteredBookings.isEmpty
                    ? const Center(child: Text('No bookings found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: admin.filteredBookings.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final booking = admin.filteredBookings[i];
                          return _BookingTile(
                            booking: booking,
                            onStatusChange: (s) =>
                                admin.updateBookingStatus(booking.id, s),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return const Color(0xFFED6C02);
      case BookingStatus.confirmed:
        return const Color(0xFF1976D2);
      case BookingStatus.declined:
        return Colors.red;
      case BookingStatus.completed:
        return const Color(0xFF2E7D32);
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  static String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final void Function(BookingStatus) onStatusChange;

  const _BookingTile(
      {required this.booking, required this.onStatusChange});

  Color get _statusColor =>
      AdminBookingsScreen._statusColor(booking.status);
  String get _statusLabel =>
      AdminBookingsScreen._statusLabel(booking.status);

  @override
  Widget build(BuildContext context) {
    final dateFormat = (DateTime d) =>
        '${d.day}/${d.month}/${d.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_month,
                    color: _statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.id.substring(0, 8)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${dateFormat(booking.startDate)} → ${dateFormat(booking.endDate)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _InfoChip(
                  icon: Icons.attach_money,
                  label:
                      '${booking.totalPrice.toStringAsFixed(0)} EGP'),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.person_outline,
                  label:
                      booking.withDriver ? 'With driver' : 'Self-drive'),
              const Spacer(),
              PopupMenuButton<BookingStatus>(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.navy, size: 20),
                tooltip: 'Change status',
                onSelected: onStatusChange,
                itemBuilder: (_) => BookingStatus.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child:
                              Text(AdminBookingsScreen._statusLabel(s)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
