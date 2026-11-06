import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/product_media_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  List<ProductMediaItem> _images = [];
  XFile? _videoFile;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty && _imageUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لانیکەم یەک وێنە زیاد بکە')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final description = _descCtrl.text.trim();
      final imageUrl = _imageUrlCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

      final localImages = _images.where((e) => e.isLocal).toList();
      final remoteUrls = _images
          .where((e) => !e.isLocal && (e.url?.isNotEmpty ?? false))
          .map((e) => e.url!)
          .toList();
      final needsMultipart =
          localImages.isNotEmpty || _videoFile != null || remoteUrls.isNotEmpty;

      late final Map<String, dynamic> res;
      if (needsMultipart) {
        final fields = <String, String>{
          'name': _nameCtrl.text.trim(),
          'price_fiat': price.toString(),
          'stock': stock.toString(),
          if (description.isNotEmpty) 'description': description,
          if (imageUrl.isNotEmpty) 'image': imageUrl,
        };
        for (var i = 0; i < remoteUrls.length; i++) {
          fields['gallery[$i]'] = remoteUrls[i];
        }

        final files = <http.MultipartFile>[];
        for (final item in localImages) {
          files.add(await ApiService.imagePart(item.file!.path));
        }
        if (_videoFile != null) {
          files.add(await ApiService.videoPart(_videoFile!.path));
        }

        res = await ApiService.ensureOk(
          () => ApiService.postMultipart(
            '/seller/products/save',
            fields: fields,
            files: files,
          ),
        );
      } else {
        res = await ApiService.ensureOk(
          () => ApiService.post('/seller/products/save', {
            'name': _nameCtrl.text.trim(),
            'price_fiat': price,
            'stock': stock,
            if (description.isNotEmpty) 'description': description,
            if (imageUrl.isNotEmpty) 'image': imageUrl,
          }),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${_nameCtrl.text.trim()}"')),
      );
      context.pop(res['product'] ?? res['data']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('بەرهەمی نوێ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ناوی بەرهەم',
                prefixIcon:
                    Icon(Icons.label_outline, color: AppColors.terracotta),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ناو پێویستە' : null,
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
                      labelText: 'نرخ (دینار)',
                      prefixIcon: Icon(Icons.attach_money,
                          color: AppColors.terracotta),
                    ),
                    validator: (v) => (double.tryParse(v ?? '') == null)
                        ? 'ژمارە بنووسە'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'بڕ لە کۆگا',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppColors.terracotta),
                    ),
                    validator: (v) => (int.tryParse(v ?? '') == null)
                        ? 'ژمارەی تەواو'
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
              onVideoChanged: ({file, clear = false}) {
                setState(() => _videoFile = clear ? null : file);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'یان لینکی وێنە (ئارەزوومەندانە)',
                prefixIcon:
                    Icon(Icons.link_rounded, color: AppColors.terracotta),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'وەسف',
                alignLabelWithHint: true,
                prefixIcon:
                    Icon(Icons.notes_rounded, color: AppColors.terracotta),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'ناردن بۆ پشکنین',
              icon: Icons.cloud_upload_rounded,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
