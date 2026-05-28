import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/car_service.dart';
import '../../services/owner_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/car_card.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String ownerId;
  const OwnerProfileScreen({super.key, required this.ownerId});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  Profile? _owner;
  List<Car> _cars = [];
  List<Review> _reviews = [];
  bool _loading = true;
  String? _brandFilter; // null = show all
  bool _uploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = await OwnerService.instance.fetchProfile(widget.ownerId);
    final cars = await CarService.instance.fetchOwnerPublicCars(widget.ownerId);
    final reviews = owner.isDealership
        ? await OwnerService.instance.fetchDealershipReviews(widget.ownerId)
        : <Review>[];
    if (mounted) {
      setState(() {
        _owner = owner;
        _cars = cars;
        _reviews = reviews;
        _loading = false;
      });
    }
  }

  Future<void> _uploadBanner() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _uploadingBanner = true);
    try {
      final url = await CarService.instance
          .uploadDealershipBanner(widget.ownerId, File(file.path));
      await OwnerService.instance.saveBannerUrl(widget.ownerId, url);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  List<Car> get _filteredCars {
    if (_brandFilter == null) return _cars;
    return _cars.where((c) => c.brand == _brandFilter).toList();
  }

  List<String> get _brands =>
      _cars.map((c) => c.brand).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_owner == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Owner not found.')));
    }

    final owner = _owner!;
    final isMe = context.read<AuthProvider>().authUser?.id == owner.id;

    return owner.isDealership
        ? _DealershipProfile(
            owner: owner,
            cars: _filteredCars,
            reviews: _reviews,
            brands: _brands,
            brandFilter: _brandFilter,
            isMe: isMe,
            uploadingBanner: _uploadingBanner,
            onBrandFilter: (b) => setState(() => _brandFilter = b),
            onUploadBanner: _uploadBanner,
          )
        : _IndividualProfile(
            owner: owner,
            cars: _cars,
            isMe: isMe,
          );
  }
}

// ─────────────────────────────────────────────────────────────
// INDIVIDUAL OWNER VARIANT
// ─────────────────────────────────────────────────────────────
class _IndividualProfile extends StatelessWidget {
  final Profile owner;
  final List<Car> cars;
  final bool isMe;

  const _IndividualProfile({
    required this.owner,
    required this.cars,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Profile'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Header
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: owner.avatarUrl != null
                      ? CachedNetworkImageProvider(owner.avatarUrl!) : null,
                  child: owner.avatarUrl == null
                      ? Text(owner.fullName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(owner.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                if (owner.city != null) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white60, size: 14),
                    const SizedBox(width: 4),
                    Text(owner.city!, style: const TextStyle(color: Colors.white60)),
                  ]),
                ],
              ],
            ),
          ),
          // Stats
          _StatsRow(carCount: cars.length),
          // Car grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Listed Cars (${cars.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (cars.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No cars listed yet.')),
            )
          else
            ...cars.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: CarCard(car: c),
                )),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DEALERSHIP VARIANT
// ─────────────────────────────────────────────────────────────
class _DealershipProfile extends StatelessWidget {
  final Profile owner;
  final List<Car> cars;
  final List<Review> reviews;
  final List<String> brands;
  final String? brandFilter;
  final bool isMe;
  final bool uploadingBanner;
  final ValueChanged<String?> onBrandFilter;
  final VoidCallback onUploadBanner;

  const _DealershipProfile({
    required this.owner,
    required this.cars,
    required this.reviews,
    required this.brands,
    required this.brandFilter,
    required this.isMe,
    required this.uploadingBanner,
    required this.onBrandFilter,
    required this.onUploadBanner,
  });

  double get _avgRating {
    if (reviews.isEmpty) return 0;
    return reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner + AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  owner.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: owner.bannerUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.navyDark),
                        )
                      : Container(color: AppColors.navyDark),
                  // Dark overlay at bottom for text legibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  // Upload banner button (owner only)
                  if (isMe)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: uploadingBanner
                          ? const SizedBox(
                              width: 28, height: 28,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : FloatingActionButton.small(
                              onPressed: onUploadBanner,
                              backgroundColor: Colors.white24,
                              child: const Icon(
                                  Icons.camera_alt_outlined, color: Colors.white),
                            ),
                    ),
                ],
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dealership name + verified badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          owner.businessName ?? owner.fullName,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (owner.verified) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Verified Dealership',
                          child: Row(
                            children: [
                              const Icon(Icons.verified,
                                  color: AppColors.gold, size: 22),
                              const SizedBox(width: 4),
                              Text('Verified',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (owner.city != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14,
                          color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(owner.city!, style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.grey600)),
                    ]),
                  ),
                const SizedBox(height: 16),

                // Stats
                _StatsRow(
                    carCount: cars.length,
                    reviewCount: reviews.length,
                    avgRating: reviews.isEmpty ? null : _avgRating),
                const SizedBox(height: 24),

                // Brand filter chips
                if (brands.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Filter by Brand',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  _BrandFilterRow(
                    brands: brands,
                    selected: brandFilter,
                    onSelected: onBrandFilter,
                  ),
                  const SizedBox(height: 20),
                ],

                // Cars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Fleet (${cars.length})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                if (cars.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No cars match this filter.')),
                  )
                else
                  ...cars.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: CarCard(car: c),
                      )),

                // Reviews
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Text('Reviews (${reviews.length})',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: AppColors.gold, size: 18),
                      Text(_avgRating.toStringAsFixed(1),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  ...reviews.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _ReviewCard(review: r),
                      )),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int carCount;
  final int? reviewCount;
  final double? avgRating;

  const _StatsRow({required this.carCount, this.reviewCount, this.avgRating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(label: 'Cars', value: '$carCount'),
        if (reviewCount != null)
          _Stat(label: 'Reviews', value: '$reviewCount'),
        if (avgRating != null)
          _Stat(
              label: 'Rating',
              value: avgRating!.toStringAsFixed(1),
              icon: Icons.star),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _Stat({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.gold, size: 18),
              const SizedBox(width: 2),
            ],
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }
}

// ── Brand Filter Row ──────────────────────────────────────────
class _BrandFilterRow extends StatelessWidget {
  final List<String> brands;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _BrandFilterRow({
    required this.brands,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              selectedColor: AppColors.gold,
              checkmarkColor: AppColors.navy,
            ),
          ),
          ...brands.map((b) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(b),
                  selected: selected == b,
                  onSelected: (_) => onSelected(selected == b ? null : b),
                  selectedColor: AppColors.gold,
                  checkmarkColor: AppColors.navy,
                ),
              )),
        ],
      ),
    );
  }
}

// ── Review Card ───────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Star rating
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.gold,
                  )),
                ),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}