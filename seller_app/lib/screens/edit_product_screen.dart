import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_transitions.dart';
import '../widgets/product_media_picker.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.productId});
  final String productId;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<ProductMediaItem> _images = [];
  XFile? _videoFile;
  String? _existingVideoUrl;
  bool _clearVideo = false;

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res =
          await ApiService.get('/seller/products/${widget.productId}');
      if (res['status'] == 'success') {
        final product =
            (res['data'] ?? res['product']) as Map<String, dynamic>?;
        _nameCtrl.text = (product?['name'] ?? '').toString();
        _priceCtrl.text = (product?['price_fiat'] ?? '').toString();
        _stockCtrl.text = (product?['stock'] ?? '').toString();
        _descCtrl.text = (product?['description'] ?? '').toString();

        final gallery = <String>[];
        final rawGallery = product?['gallery'];
        if (rawGallery is List) {
          for (final item in rawGallery) {
            final url = item?.toString() ?? '';
            if (url.isNotEmpty) gallery.add(url);
          }
        }
        final cover = (product?['image'] ?? '').toString();
        if (cover.isNotEmpty && !gallery.contains(cover)) {
          gallery.insert(0, cover);
        }
        _images = gallery
            .take(5)
            .map((url) => ProductMediaItem.remote(url))
            .toList();

        final video = (product?['video'] ?? '').toString();
        _existingVideoUrl = video.isEmpty ? null : video;
        _videoFile = null;
        _clearVideo = false;
      }
    } catch (e) {
      debugPrint('Product fetch: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
      final localImages = _images.where((e) => e.isLocal).toList();
      final remoteUrls = _images
          .where((e) => !e.isLocal && (e.url?.isNotEmpty ?? false))
          .map((e) => e.url!)
          .toList();

      final fields = <String, String>{
        'name': _nameCtrl.text.trim(),
        'price_fiat': price.toString(),
        'stock': stock.toString(),
        'description': _descCtrl.text.trim(),
        if (_clearVideo) 'clear_video': '1',
      };
      for (var i = 0; i < remoteUrls.length; i++) {
        fields['gallery[$i]'] = remoteUrls[i];
      }
      if (remoteUrls.isEmpty && localImages.isEmpty) {
        fields['gallery'] = '[]';
      }

      final files = <http.MultipartFile>[];
      for (final item in localImages) {
        files.add(await ApiService.imagePart(item.file!.path));
      }
      if (_videoFile != null) {
        files.add(await ApiService.videoPart(_videoFile!.path));
      }

      final res = await ApiService.ensureOk(
        () => ApiService.putMultipart(
          '/seller/products/${widget.productId}',
          fields: fields,
          files: files,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Saved')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this listing?'),
        content:
            const Text('Buyers will no longer be able to purchase this item.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      final res =
          await ApiService.delete('/seller/products/${widget.productId}');
      if (!mounted) return;
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing removed')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleting ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          ),
        ],
      ),
      body: FadeSlideIn(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item name',
                prefixIcon:
                    Icon(Icons.label_outline, color: AppColors.terracotta),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price (USD)',
                      prefixIcon: Icon(Icons.attach_money,
                          color: AppColors.terracotta),
                    ),
                    validator: (v) => (double.tryParse(v ?? '') == null)
                        ? 'Enter a number'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppColors.terracotta),
                    ),
                    validator: (v) => (int.tryParse(v ?? '') == null)
                        ? 'Whole number'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ProductMediaPicker(
              images: _images,
              onImagesChanged: (next) => setState(() => _images = next),
              videoFile: _videoFile,
              existingVideoUrl: _existingVideoUrl,
              clearVideo: _clearVideo,
              onVideoChanged: ({file, clear = false}) {
                setState(() {
                  if (clear) {
                    _videoFile = null;
                    _clearVideo = true;
                  } else {
                    _videoFile = file;
                    _clearVideo = false;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon:
                    Icon(Icons.notes_rounded, color: AppColors.terracotta),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Save Changes',
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
