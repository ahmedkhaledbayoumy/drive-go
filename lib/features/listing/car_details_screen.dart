import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/car_service.dart';
import '../../services/owner_service.dart';
import '../../theme/app_colors.dart';

class CarDetailsScreen extends StatefulWidget {
  final String carId;
  const CarDetailsScreen({super.key, required this.carId});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  Car? _car;
  Profile? _owner;
  bool _loading = true;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final car = await CarService.instance.fetchCar(widget.carId);
      final owner = await OwnerService.instance.fetchProfile(car.ownerId);
      if (mounted) setState(() { _car = car; _owner = owner; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_car == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Car not found.')),
      );
    }

    final car = _car!;
    final owner = _owner;
    final auth = context.read<AuthProvider>();
    final isOwner = auth.currentProfile?.id == car.ownerId;
    final fmt = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Photo gallery as SliverAppBar ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoGallery(
                photos: car.photos,
                currentIndex: _photoIndex,
                onChanged: (i) => setState(() => _photoIndex = i),
              ),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit listing',
                  onPressed: () => context.push('/my-listings/edit/${car.id}'),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + status badge ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(status: car.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.year} · ${car.color}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(car.city, style: theme.textTheme.bodyMedium),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Specs grid ──
                  Text('Specs',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SpecsGrid(car: car),

                  const SizedBox(height: 24),

                  // ── Pricing tiers ──
                  Text('Pricing',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _PricingCard(car: car, fmt: fmt),

                  const SizedBox(height: 24),

                  // ── Description ──
                  Text('About this car',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(car.description, style: theme.textTheme.bodyMedium),

                  // ── Owner section ──
                  if (owner != null) ...[
                    const SizedBox(height: 24),
                    _OwnerTile(
                      owner: owner,
                      onTap: () => context.push('/owner/${owner.id}'),
                    ),
                  ],

                  const SizedBox(height: 100), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Contact / action buttons ──
      bottomNavigationBar: _BottomBar(
        car: car,
        owner: owner,
        isOwner: isOwner,
        fmt: fmt,
        onWhatsApp: () {
          final phone = owner?.phone;
          if (phone != null) _launchWhatsApp(phone);
        },
        onPhone: () {
          final phone = owner?.phone;
          if (phone != null) _launchPhone(phone);
        },
        onRequest: () {
          // V4 will handle booking flow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking coming in V4!')),
          );
        },
      ),
    );
  }
}

// ── Photo Gallery ─────────────────────────────────────────────
class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _PhotoGallery({
    required this.photos,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: onChanged,
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: photos[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        ),
        // Dot indicators
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentIndex == i ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: currentIndex == i ? AppColors.gold : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        // Photo count badge
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentIndex + 1}/${photos.length}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final CarStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CarStatus.available => (AppColors.statusAvailable, 'Available'),
      CarStatus.pendingConfirmation => (AppColors.statusPending, 'Pending'),
      CarStatus.booked => (AppColors.statusBooked, 'Booked'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Specs Grid ────────────────────────────────────────────────
class _SpecsGrid extends StatelessWidget {
  final Car car;
  const _SpecsGrid({required this.car});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.settings_outlined, 'Transmission', car.transmission.name),
      (Icons.local_gas_station_outlined, 'Fuel', car.fuelType.name),
      (Icons.calendar_today_outlined, 'Year', '${car.year}'),
      (Icons.palette_outlined, 'Color', car.color),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3,
      children: items.map((item) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(item.$1, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$2,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                    Text(item.$3,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Pricing Card ──────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  final Car car;
  final NumberFormat fmt;
  const _PricingCard({required this.car, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PricingRow(label: 'Per Day', price: fmt.format(car.pricePerDay), highlight: true),
          if (car.pricePerWeek != null) ...[
            const Divider(height: 1),
            _PricingRow(label: 'Per Week', price: fmt.format(car.pricePerWeek)),
          ],
          if (car.pricePerMonth != null) ...[
            const Divider(height: 1),
            _PricingRow(label: 'Per Month', price: fmt.format(car.pricePerMonth)),
          ],
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String price;
  final bool highlight;
  const _PricingRow({required this.label, required this.price, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            price,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.gold : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Owner Tile ────────────────────────────────────────────────
class _OwnerTile extends StatelessWidget {
  final Profile owner;
  final VoidCallback onTap;
  const _OwnerTile({required this.owner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: owner.avatarUrl != null
                  ? CachedNetworkImageProvider(owner.avatarUrl!)
                  : null,
              child: owner.avatarUrl == null
                  ? Text(owner.fullName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(owner.isDealership
                          ? (owner.businessName ?? owner.fullName)
                          : owner.fullName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (owner.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: AppColors.gold),
                      ],
                    ],
                  ),
                  Text(
                    owner.isDealership ? 'Dealership' : 'Individual Owner',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Action Bar ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final Car car;
  final Profile? owner;
  final bool isOwner;
  final NumberFormat fmt;
  final VoidCallback onWhatsApp;
  final VoidCallback onPhone;
  final VoidCallback onRequest;

  const _BottomBar({
    required this.car,
    required this.owner,
    required this.isOwner,
    required this.fmt,
    required this.onWhatsApp,
    required this.onPhone,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = owner?.phone != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            if (!isOwner && hasPhone) ...[
              // WhatsApp button
              _CircleAction(
                icon: Icons.chat_outlined,
                color: const Color(0xFF25D366),
                tooltip: 'WhatsApp',
                onTap: onWhatsApp,
              ),
              const SizedBox(width: 10),
              // Phone button
              _CircleAction(
                icon: Icons.call_outlined,
                color: AppColors.navy,
                tooltip: 'Call',
                onTap: onPhone,
              ),
              const SizedBox(width: 12),
            ],
            // Main CTA
            Expanded(
              child: FilledButton(
                onPressed: car.status == CarStatus.available && !isOwner
                    ? onRequest
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isOwner
                    ? 'Your Listing'
                    : car.status == CarStatus.available
                        ? 'Request to Rent'
                        : 'Not Available'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
