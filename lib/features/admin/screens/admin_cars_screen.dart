import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminCarsScreen extends StatefulWidget {
  const AdminCarsScreen({super.key});

  @override
  State<AdminCarsScreen> createState() => _AdminCarsScreenState();
}

class _AdminCarsScreenState extends State<AdminCarsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.navyLight,
        foregroundColor: Colors.white,
        title: const Text('Car Listings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: admin.loadAll),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by brand, model or city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          admin.filterCars(search: '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => admin.filterCars(search: v),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${admin.filteredCars.length} listing(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: admin.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.navyLight))
                : admin.filteredCars.isEmpty
                    ? const Center(child: Text('No cars found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: admin.filteredCars.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final car = admin.filteredCars[i];
                          return _CarTile(
                            car: car,
                            onDelete: () =>
                                _confirmDelete(context, admin, car),
                            onStatusChange: (s) =>
                                admin.updateCarStatus(car.id, s),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AdminProvider admin, Car car) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
            'Delete "${car.brand} ${car.model} (${car.year})"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await admin.deleteCar(car.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${car.brand} ${car.model} deleted'),
                      backgroundColor: Colors.red[700]),
                );
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  final Car car;
  final VoidCallback onDelete;
  final void Function(CarStatus) onStatusChange;

  const _CarTile({
    required this.car,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color get _statusColor {
    switch (car.status) {
      case CarStatus.available:
        return AppColors.statusAvailable;
      case CarStatus.pendingConfirmation:
        return AppColors.statusPending;
      case CarStatus.booked:
        return AppColors.statusBooked;
    }
  }

  String get _statusLabel {
    switch (car.status) {
      case CarStatus.available:
        return 'Available';
      case CarStatus.pendingConfirmation:
        return 'Pending';
      case CarStatus.booked:
        return 'Booked';
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          // Car photo or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: car.photos.isNotEmpty
                ? Image.network(
                    car.photos.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.brand} ${car.model}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${car.year} · ${car.city} · ${car.pricePerDay.toStringAsFixed(0)} EGP/day',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              PopupMenuButton<CarStatus>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                tooltip: 'Change status',
                onSelected: onStatusChange,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: CarStatus.available,
                    child: Text('Set Available'),
                  ),
                  const PopupMenuItem(
                    value: CarStatus.pendingConfirmation,
                    child: Text('Set Pending'),
                  ),
                  const PopupMenuItem(
                    value: CarStatus.booked,
                    child: Text('Set Booked'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete listing',
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.grey200,
      child: const Icon(Icons.directions_car,
          color: AppColors.grey600),
    );
  }
}
