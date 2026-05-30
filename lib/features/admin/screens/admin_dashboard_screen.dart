import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../services/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final stats = admin.stats;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => admin.loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.signOut();
            },
          ),
        ],
      ),
      body: admin.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy))
          : admin.error != null
              ? _ErrorView(
                  error: admin.error!,
                  onRetry: admin.loadAll,
                )
              : RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: admin.loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Welcome
                      Text(
                        'Welcome back, Admin',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening on Drive Go today.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Stats grid
                      if (stats != null) ...[
                        _SectionTitle('Overview'),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _StatCard(
                              label: 'Total Users',
                              value: '${stats.totalUsers}',
                              icon: Icons.people_alt_outlined,
                              color: AppColors.navy,
                            ),
                            _StatCard(
                              label: 'Car Listings',
                              value: '${stats.totalCars}',
                              icon: Icons.directions_car_outlined,
                              color: AppColors.navyLight,
                            ),
                            _StatCard(
                              label: 'Total Bookings',
                              value: '${stats.totalBookings}',
                              icon: Icons.calendar_month_outlined,
                              color: const Color(0xFF2E7D32),
                            ),
                            _StatCard(
                              label: 'Revenue (EGP)',
                              value: '${stats.totalRevenue}',
                              icon: Icons.attach_money,
                              color: AppColors.goldDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Pending Bookings',
                                value: '${stats.pendingBookings}',
                                icon: Icons.hourglass_empty,
                                color: const Color(0xFFED6C02),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Active Rentals',
                                value: '${stats.activeBookings}',
                                icon: Icons.drive_eta_outlined,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                        if (stats.pendingVerifications > 0) ...[
                          const SizedBox(height: 12),
                          _AlertBanner(
                            message:
                                '${stats.pendingVerifications} dealership(s) awaiting verification.',
                            onTap: () => context.push('/admin/users'),
                          ),
                        ],
                      ],

                      const SizedBox(height: 28),
                      _SectionTitle('Management'),
                      const SizedBox(height: 12),

                      // Nav cards
                      _NavCard(
                        icon: Icons.people_alt_outlined,
                        color: AppColors.navy,
                        title: 'User Management',
                        subtitle:
                            'View, search, verify dealerships, delete accounts',
                        onTap: () => context.push('/admin/users'),
                      ),
                      const SizedBox(height: 12),
                      _NavCard(
                        icon: Icons.directions_car_outlined,
                        color: AppColors.navyLight,
                        title: 'Car Listings',
                        subtitle:
                            'Browse all listings, change status, remove cars',
                        onTap: () => context.push('/admin/cars'),
                      ),
                      const SizedBox(height: 12),
                      _NavCard(
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFF2E7D32),
                        title: 'Bookings',
                        subtitle:
                            'Monitor all rentals, update status, resolve disputes',
                        onTap: () => context.push('/admin/bookings'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _AlertBanner({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          border: Border.all(color: const Color(0xFFED6C02)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFED6C02), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Color(0xFFED6C02), fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFED6C02), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load data',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
