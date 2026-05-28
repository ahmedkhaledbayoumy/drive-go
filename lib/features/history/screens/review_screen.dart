import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../providers/history_provider.dart';

// ── ReviewScreen ──────────────────────────────────────────────────────────────
// Route: /review/:bookingId
// Only reachable for completed Dealership bookings where review_submitted=false.
// ─────────────────────────────────────────────────────────────────────────────

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  BookingSummary? get _booking =>
      context.read<HistoryProvider>().findById(widget.bookingId);

  Future<void> _submit() async {
    if (_rating == 0) {
      _showSnack('Please select a star rating.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final booking = _booking;
    if (booking == null) {
      _showSnack('Booking not found.');
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.currentProfile == null) return;

    setState(() => _submitting = true);

    final success = await context.read<HistoryProvider>().submitReview(
          bookingId: booking.id,
          customerId: auth.currentProfile!.id,
          dealershipId: booking.ownerId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      _showSnack('Review submitted! Thank you.');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    } else {
      _showSnack('Could not submit review. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final booking = context.watch<HistoryProvider>().findById(widget.bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        centerTitle: false,
      ),
      body: booking == null
          ? const Center(child: Text('Booking not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dealership info card
                    _DealershipInfo(booking: booking),
                    const SizedBox(height: 28),

                    // Star rating
                    Text('Your Rating', style: tt.titleSmall),
                    const SizedBox(height: 10),
                    _StarRating(
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                    if (_rating > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        _ratingLabel(_rating),
                        style: tt.bodySmall
                            ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Comment
                    Text('Your Review', style: tt.titleSmall),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _commentController,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Tell others about your experience with this dealership...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Please write at least 10 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit Review',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _ratingLabel(double r) => switch (r) {
        1 => 'Poor',
        2 => 'Below Average',
        3 => 'Average',
        4 => 'Good',
        _ => 'Excellent!',
      };
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DealershipInfo extends StatelessWidget {
  const _DealershipInfo({required this.booking});
  final BookingSummary booking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primaryContainer,
            backgroundImage: booking.ownerPhotoUrl != null
                ? NetworkImage(booking.ownerPhotoUrl!)
                : null,
            child: booking.ownerPhotoUrl == null
                ? Icon(Icons.store_outlined,
                    color: cs.onPrimaryContainer)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.dealershipName ?? booking.ownerName ?? 'Dealership',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  booking.carTitle,
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              value >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 38,
              color: value >= starValue
                  ? Colors.amber.shade600
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
