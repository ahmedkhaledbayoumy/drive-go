import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../services/auth_provider.dart';
import '../../services/car_service.dart';
import '../../theme/app_colors.dart';

class RentMyCarScreen extends StatefulWidget {
  /// If provided, we're editing an existing listing.
  final String? editCarId;
  const RentMyCarScreen({super.key, this.editCarId});

  @override
  State<RentMyCarScreen> createState() => _RentMyCarScreenState();
}

class _RentMyCarScreenState extends State<RentMyCarScreen> {
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

  // Dropdowns
  Transmission _transmission = Transmission.automatic;
  FuelType _fuelType = FuelType.petrol;

  // Photos: mix of existing URLs (String) and new files (XFile)
  final List<dynamic> _photos = []; // String | XFile
  bool _uploading = false;

  static const int _maxPhotos = 15;

  @override
  void dispose() {
    for (final c in [
      _brandCtrl, _modelCtrl, _yearCtrl, _colorCtrl, _cityCtrl,
      _descCtrl, _pricePerDayCtrl, _pricePerWeekCtrl, _pricePerMonthCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Maximum 15 photos reached.')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final toAdd = picked.take(remaining).toList();
    setState(() => _photos.addAll(toAdd));
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add at least one photo.')));
      return;
    }

    setState(() => _uploading = true);

    try {
      final auth = context.read<AuthProvider>();
      final ownerId = auth.authUser!.id;

      // Upload any new XFile photos; keep existing URL strings as-is.
      final photoUrls = <String>[];
      for (final p in _photos) {
        if (p is String) {
          photoUrls.add(p);
        } else if (p is XFile) {
          final url = await CarService.instance
              .uploadCarPhoto(ownerId, File(p.path));
          photoUrls.add(url);
        }
      }

      await CarService.instance.createCar(
        ownerId: ownerId,
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: int.parse(_yearCtrl.text.trim()),
        color: _colorCtrl.text.trim(),
        transmission: _transmission,
        fuelType: _fuelType,
        city: _cityCtrl.text.trim(),
        pricePerDay: double.parse(_pricePerDayCtrl.text.trim()),
        pricePerWeek: _pricePerWeekCtrl.text.isEmpty
            ? null
            : double.parse(_pricePerWeekCtrl.text.trim()),
        pricePerMonth: _pricePerMonthCtrl.text.isEmpty
            ? null
            : double.parse(_pricePerMonthCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        photos: photoUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing created! 🎉')));
        context.go('/my-listings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editCarId == null ? 'List My Car' : 'Edit Listing'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Photo Picker ──
            _SectionHeader('Photos (${_photos.length}/$_maxPhotos)'),
            const SizedBox(height: 10),
            _PhotoPickerGrid(
              photos: _photos,
              maxPhotos: _maxPhotos,
              onAdd: _pickPhotos,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 24),

            // ── Car Details ──
            _SectionHeader('Car Details'),
            const SizedBox(height: 12),
            _row(
              _TextInput(controller: _brandCtrl, label: 'Brand', hint: 'e.g. Toyota'),
              _TextInput(controller: _modelCtrl, label: 'Model', hint: 'e.g. Corolla'),
            ),
            const SizedBox(height: 12),
            _row(
              _TextInput(
                controller: _yearCtrl,
                label: 'Year',
                hint: '2020',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1990 || n > 2026) return 'Invalid year';
                  return null;
                },
              ),
              _TextInput(controller: _colorCtrl, label: 'Color', hint: 'e.g. White'),
            ),
            const SizedBox(height: 12),
            _DropdownInput<Transmission>(
              label: 'Transmission',
              value: _transmission,
              items: Transmission.values,
              itemLabel: (t) => t.name[0].toUpperCase() + t.name.substring(1),
              onChanged: (v) => setState(() => _transmission = v!),
            ),
            const SizedBox(height: 12),
            _DropdownInput<FuelType>(
              label: 'Fuel Type',
              value: _fuelType,
              items: FuelType.values,
              itemLabel: (f) => f.name[0].toUpperCase() + f.name.substring(1),
              onChanged: (v) => setState(() => _fuelType = v!),
            ),
            const SizedBox(height: 12),
            _TextInput(
                controller: _cityCtrl, label: 'City', hint: 'e.g. Cairo'),
            const SizedBox(height: 24),

            // ── Pricing ──
            _SectionHeader('Pricing (EGP)'),
            const SizedBox(height: 12),
            _TextInput(
              controller: _pricePerDayCtrl,
              label: 'Price per Day *',
              hint: '500',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (double.tryParse(v ?? '') == null) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _row(
              _TextInput(
                controller: _pricePerWeekCtrl,
                label: 'Price per Week',
                hint: '3000 (optional)',
                keyboardType: TextInputType.number,
                required: false,
              ),
              _TextInput(
                controller: _pricePerMonthCtrl,
                label: 'Price per Month',
                hint: '10000 (optional)',
                keyboardType: TextInputType.number,
                required: false,
              ),
            ),
            const SizedBox(height: 24),

            // ── Description ──
            _SectionHeader('Description'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tell renters about your car',
                hintText: 'Clean interior, full service history...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 36),

            // ── Submit ──
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _uploading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.navy))
                    : const Text('Submit Listing'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _row(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
}

// ── Section Header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
      );
}

// ── Text Input ────────────────────────────────────────────────
class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool required;

  const _TextInput({
    required this.controller,
    required this.label,
    this.hint = '',
    this.keyboardType,
    this.validator,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

// ── Dropdown Input ────────────────────────────────────────────
class _DropdownInput<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownInput({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items
          .map((t) => DropdownMenuItem<T>(value: t, child: Text(itemLabel(t))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Photo Picker Grid ─────────────────────────────────────────
class _PhotoPickerGrid extends StatelessWidget {
  final List<dynamic> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoPickerGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxPhotos;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        // Existing / picked photos
        ...photos.asMap().entries.map((e) {
          final i = e.key;
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
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
              if (i == 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Cover',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                  ),
                ),
            ],
          );
        }),
        // Add button
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.05),
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: AppColors.navy),
                  SizedBox(height: 4),
                  Text('Add Photo',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}