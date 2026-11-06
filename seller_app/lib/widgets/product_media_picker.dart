import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';

/// One gallery slot: either an existing remote URL or a newly picked local file.
class ProductMediaItem {
  const ProductMediaItem.remote(String this.url) : file = null;
  const ProductMediaItem.local(XFile this.file) : url = null;

  final String? url;
  final XFile? file;

  bool get isLocal => file != null;
}

/// Pick up to [maxImages] photos + one product video for create/edit.
class ProductMediaPicker extends StatefulWidget {
  const ProductMediaPicker({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.videoFile,
    this.existingVideoUrl,
    this.clearVideo = false,
    required this.onVideoChanged,
    this.maxImages = 5,
  });

  final List<ProductMediaItem> images;
  final ValueChanged<List<ProductMediaItem>> onImagesChanged;
  final XFile? videoFile;
  final String? existingVideoUrl;
  final bool clearVideo;
  final void Function({XFile? file, bool clear}) onVideoChanged;
  final int maxImages;

  @override
  State<ProductMediaPicker> createState() => _ProductMediaPickerState();
}

class _ProductMediaPickerState extends State<ProductMediaPicker> {
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final remaining = widget.maxImages - widget.images.length;
    if (remaining <= 0) return;
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked.isEmpty) return;
      final next = [
        ...widget.images,
        ...picked.take(remaining).map(ProductMediaItem.local),
      ];
      widget.onImagesChanged(next);
    } catch (e) {
      _toast('Could not open gallery: $e');
    }
  }

  Future<void> _pickCamera() async {
    if (widget.images.length >= widget.maxImages) return;
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (shot == null) return;
      widget.onImagesChanged([...widget.images, ProductMediaItem.local(shot)]);
    } catch (e) {
      _toast('Could not open camera: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final clip = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (clip == null) return;
      widget.onVideoChanged(file: clip, clear: false);
    } catch (e) {
      _toast('Could not open video picker: $e');
    }
  }

  void _removeImage(int index) {
    final next = [...widget.images]..removeAt(index);
    widget.onImagesChanged(next);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _hasVideo =>
      widget.videoFile != null ||
      (!widget.clearVideo && (widget.existingVideoUrl?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'وێنەکان',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              '$count / ${widget.maxImages}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'تا ٥ وێنە زیاد بکە — یەکەمیان وێنەی سەرەکی دەبێت.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < widget.images.length; i++)
                _ImageTile(
                  item: widget.images[i],
                  isCover: i == 0,
                  onRemove: () => _removeImage(i),
                ),
              if (count < widget.maxImages) ...[
                _AddTile(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'گەلەری',
                  onTap: _pickImages,
                ),
                if (!kIsWeb)
                  _AddTile(
                    icon: Icons.photo_camera_outlined,
                    label: 'کامێرا',
                    onTap: _pickCamera,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'ڤیدیۆ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'یەک ڤیدیۆی کورت (MP4) — کڕیارەکان لە پەڕەی بەرهەم دەیبینن.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        if (_hasVideo)
          _VideoCard(
            file: widget.videoFile,
            url: widget.clearVideo ? null : widget.existingVideoUrl,
            onReplace: _pickVideo,
            onRemove: () => widget.onVideoChanged(file: null, clear: true),
          )
        else
          _AddVideoButton(onTap: _pickVideo),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.item,
    required this.isCover,
    required this.onRemove,
  });

  final ProductMediaItem item;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCover ? AppColors.terracotta : AppColors.border,
                width: isCover ? 2 : 1,
              ),
              color: AppColors.paperSolid,
            ),
            clipBehavior: Clip.antiAlias,
            child: item.isLocal
                ? Image.file(File(item.file!.path), fit: BoxFit.cover)
                : Image.network(
                    item.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'سەرەکی',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Material(
        color: AppColors.sageLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 96,
            height: 108,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.terracotta, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddVideoButton extends StatelessWidget {
  const _AddVideoButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2330), Color(0xFF0A0A0A)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.videocam_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              const Text(
                'زیادکردنی ڤیدیۆی بەرهەم',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'تا ٢ خولەک · MP4',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.file,
    required this.url,
    required this.onReplace,
    required this.onRemove,
  });

  final XFile? file;
  final String? url;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label = file?.name ??
        (url != null ? 'ڤیدیۆی هەڵگیراو' : 'ڤیدیۆ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2330), Color(0xFF0F141C)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file != null ? 'ئامادەیە بۆ ناردن' : 'لەسەر سێرڤەر هەیە',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'گۆڕین',
            onPressed: onReplace,
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white70),
          ),
          IconButton(
            tooltip: 'سڕینەوە',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFFF8A8A)),
          ),
        ],
      ),
    );
  }
}
