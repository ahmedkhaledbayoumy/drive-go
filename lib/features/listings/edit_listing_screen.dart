import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/car_service.dart';
import '../../theme/app_colors.dart';

class EditListingScreen extends StatefulWidget {
  final String carId;
  const EditListingScreen({super.key, required this.carId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pricePerDayCtrl = TextEditingController();
  final _pricePerWeekCtrl = TextEditingController();
  final _pricePerMonthCtrl = TextEditingController();

  Transmission _transmission = Transmission.automatic;
  FuelType _fuelType = FuelType.petrol;

  // Mix of String (existing URL) and XFile (new pick)
  final List<dynamic> _photos = [];
  static const int _maxPhotos = 15;
  bool _loading = true;
  bool _saving = false;
  Car? _original;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  @override
  void dispose() {
    for (final c in [
      _brandCtrl, _modelCtrl, _yearCtrl, _colorCtrl, _cityCtrl,
      _descCtrl, _pricePerDayCtrl, _pricePerWeekCtrl, _pricePerMonthCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _loadCar() async {
    final car = await CarService.instance.fetchCar(widget.carId);
    _original = car;
    _brandCtrl.text = car.brand;
    _modelCtrl.text = car.model;
    _yearCtrl.text = '${car.year}';
    _colorCtrl.text = car.color;
    _cityCtrl.text = car.city;
    _descCtrl.text = car.description;
    _pricePerDayCtrl.text = '${car.pricePerDay.toStringAsFixed(0)}';
    _pricePerWeekCtrl.text = car.pricePerWeek != null
        ? car.pricePerWeek!.toStringAsFixed(0) : '';
    _pricePerMonthCtrl.text = car.pricePerMonth != null
        ? car.pricePerMonth!.toStringAsFixed(0) : '';
    _transmission = car.transmission;
    _fuelType = car.fuelType;
    _photos.addAll(car.photos);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _photos.addAll(picked.take(remaining)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one photo.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final ownerId = context.read<AuthProvider>().authUser!.id;

      // Delete removed photos from storage
      final removedUrls = (_original?.photos ?? [])
          .where((u) => !_photos.contains(u))
          .toList();
      for (final url in removedUrls) {
        await CarService.instance.deleteCarPhoto(url);
      }

      // Upload new XFiles
      final photoUrls = <String>[];
      for (final p in _photos) {
        if (p is String) {
          photoUrls.add(p);
        } else if (p is XFile) {
          final url =
              await CarService.instance.uploadCarPhoto(ownerId, File(p.path));
          photoUrls.add(url);
        }
      }

      await CarService.instance.updateCar(widget.carId, {
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'year': int.parse(_yearCtrl.text.trim()),
        'color': _colorCtrl.text.trim(),
        'transmission': _transmission.name,
        'fuel_type': _fuelType.name,
        'city': _cityCtrl.text.trim(),
        'price_per_day': double.parse(_pricePerDayCtrl.text.trim()),
        'price_per_week': _pricePerWeekCtrl.text.isEmpty
            ? null : double.parse(_pricePerWeekCtrl.text.trim()),
        'price_per_month': _pricePerMonthCtrl.text.isEmpty
            ? null : double.parse(_pricePerMonthCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'photos': photoUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Listing updated!')));
        context.go('/my-listings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photos
            Text('Photos (${_photos.length}/$_maxPhotos)',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 10),
            _EditPhotoGrid(
              photos: _photos,
              maxPhotos: _maxPhotos,
              onAdd: _pickPhotos,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
            const SizedBox(height: 24),

            // Fields (reuse same layout as RentMyCarScreen)
            _field(_brandCtrl, 'Brand'),
            const SizedBox(height: 12),
            _field(_modelCtrl, 'Model'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_yearCtrl, 'Year', numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_colorCtrl, 'Color')),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<Transmission>(
              value: _transmission,
              decoration: const InputDecoration(labelText: 'Transmission', border: OutlineInputBorder()),
              items: Transmission.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _transmission = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FuelType>(
              value: _fuelType,
              decoration: const InputDecoration(labelText: 'Fuel Type', border: OutlineInputBorder()),
              items: FuelType.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                  .toList(),
              onChanged: (v) => setState(() => _fuelType = v!),
            ),
            const SizedBox(height: 12),
            _field(_cityCtrl, 'City'),
            const SizedBox(height: 24),

            // Pricing
            Text('Pricing (EGP)',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 12),
            _field(_pricePerDayCtrl, 'Price per Day *', numeric: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_pricePerWeekCtrl, 'Per Week', numeric: true, required: false)),
              const SizedBox(width: 12),
              Expanded(child: _field(_pricePerMonthCtrl, 'Per Month', numeric: true, required: false)),
            ]),
            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 36),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy))
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool numeric = false, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

class _EditPhotoGrid extends StatelessWidget {
  final List<dynamic> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _EditPhotoGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        ...photos.asMap().entries.map((e) {
          final photo = e.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: photo is String
                    ? Image.network(photo, fit: BoxFit.cover)
                    : Image.file(File((photo as XFile).path), fit: BoxFit.cover),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        if (photos.length < maxPhotos)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.navy),
                  SizedBox(height: 4),
                  Text('Add', style: TextStyle(fontSize: 11, color: AppColors.navy)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}