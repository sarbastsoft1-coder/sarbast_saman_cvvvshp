import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/reviews_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

/// Form for submitting a new product review.
class WriteReviewScreen extends StatefulWidget {
  final BoutiqueProduct product;
  const WriteReviewScreen({super.key, required this.product});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_rating < 1) {
      _showError('تکایە هەڵسەنگاندن هەڵبژێرە');
      return;
    }
    setState(() => _submitting = true);

    // Tiny artificial delay so the submit feels responsive on slow devices.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    context.read<ReviewsProvider>().submit(
      productId: widget.product.id,
      name: _nameCtrl.text,
      rating: _rating,
      comment: _commentCtrl.text,
    );

    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BoutiqueColors.successGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: const Text(
          'سوپاس بۆ هەڵسەنگاندنەکەت ✓',
          style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BoutiqueColors.rose,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('نووسینی هەڵسەنگاندن')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProductHeader(product: widget.product),
              const SizedBox(height: 16),
              RoniCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('هەڵسەنگاندن'),
                    const SizedBox(height: 12),
                    Center(
                      child: _StarPicker(
                        rating: _rating,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _Label('ناوی تۆ (هەڵبژاردنە)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      maxLength: 30,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: BoutiqueColors.charcoal,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'بۆ نموونە: سارا ئەحمەد',
                        counterStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: BoutiqueColors.muted,
                          fontSize: 11,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: BoutiqueColors.dustyPink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _Label('بۆچوونی تۆ'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentCtrl,
                      maxLines: 5,
                      minLines: 4,
                      maxLength: 400,
                      inputFormatters: [LengthLimitingTextInputFormatter(400)],
                      validator: (v) {
                        final text = (v ?? '').trim();
                        if (text.length < 8) {
                          return 'تکایە لانیکەم ٨ پیت بنووسە';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: BoutiqueColors.charcoal,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'چۆن بوو ئەزموونەکەت لەگەڵ ئەم بەرهەمە؟',
                        counterStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: BoutiqueColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GoldButton(
                label: _submitting ? 'لە ناردن...' : 'ناردنی هەڵسەنگاندن',
                icon: _submitting ? null : Icons.send_rounded,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});
  final BoutiqueProduct product;

  @override
  Widget build(BuildContext context) => RoniCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 64,
            height: 64,
            child: ProductArtwork(product: product),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 10.5,
                  color: BoutiqueColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                product.seller,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: BoutiqueColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: BoutiqueColors.charcoal,
    ),
  );
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.rating, required this.onChanged});
  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Flexible so the picker still fits on a 320 px screen.
      for (int i = 1; i <= 5; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => onChanged(i.toDouble()),
              child: Icon(
                i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 40,
                color: i <= rating
                    ? BoutiqueColors.goldBright
                    : BoutiqueColors.border,
              ),
            ),
          ),
        ),
      const SizedBox(width: 10),
      Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: BoutiqueColors.dustyPink,
        ),
      ),
    ],
  );
}
