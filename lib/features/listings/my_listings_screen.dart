import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/car_service.dart';
import '../../theme/app_colors.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Car>? _cars;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ownerId = context.read<AuthProvider>().authUser?.id;
    if (ownerId == null) return;
    final cars = await CarService.instance.fetchOwnerCars(ownerId);
    if (mounted) setState(() { _cars = cars; _loading = false; });
  }

  Future<void> _updateStatus(Car car, CarStatus newStatus) async {
    await CarService.instance.updateStatus(car.id, newStatus);
    _load();
  }

  Future<void> _deleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Remove ${car.brand} ${car.model}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CarService.instance.deleteCar(car);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/list-car'),
        icon: const Icon(Icons.add),
        label: const Text('List a Car'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_cars == null || _cars!.isEmpty)
              ? _EmptyState(onAdd: () => context.push('/list-car'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    itemCount: _cars!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ListingCard(
                      car: _cars![i],
                      onEdit: () => context.push('/my-listings/edit/${_cars![i].id}'),
                      onView: () => context.push('/car/${_cars![i].id}'),
                      onDelete: () => _deleteCar(_cars![i]),
                      onStatusChange: (s) => _updateStatus(_cars![i], s),
                    ),
                  ),
                ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final Car car;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final ValueChanged<CarStatus> onStatusChange;

  const _ListingCard({
    required this.car,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: car.photos.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                      )
                    : CachedNetworkImage(
                        imageUrl: car.photos.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
              ),
              Positioned(
                top: 10, right: 10,
                child: _StatusChip(
                  status: car.status,
                  onChanged: onStatusChange,
                ),
              ),
            ],
          ),
          // Details row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${car.brand} ${car.model}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${car.year} · ${car.city}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Text(
                  '${fmt.format(car.pricePerDay)}/day',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          // Action buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View')),
                TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit')),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Chip with dropdown ─────────────────────────────────
class _StatusChip extends StatelessWidget {
  final CarStatus status;
  final ValueChanged<CarStatus> onChanged;

  const _StatusChip({required this.status, required this.onChanged});

  Color get _color => switch (status) {
        CarStatus.available => AppColors.statusAvailable,
        CarStatus.pendingConfirmation => AppColors.statusPending,
        CarStatus.booked => AppColors.statusBooked,
      };

  String get _label => switch (status) {
        CarStatus.available => 'Available',
        CarStatus.pendingConfirmation => 'Pending',
        CarStatus.booked => 'Booked',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CarStatus>(
      onSelected: onChanged,
      itemBuilder: (_) => CarStatus.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.name)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 80, color: AppColors.navy.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No listings yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.navy.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('List Your First Car'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold, foregroundColor: AppColors.navy),
          ),
        ],
      ),
    );
  }
}