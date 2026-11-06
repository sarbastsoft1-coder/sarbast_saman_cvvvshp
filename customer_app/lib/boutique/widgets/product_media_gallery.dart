import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/theme/boutique_colors.dart';
import '../models/product.dart';
import 'product_art.dart';

/// Full-bleed product media: swipeable photos + cinematic video player.
class ProductMediaGallery extends StatefulWidget {
  const ProductMediaGallery({
    super.key,
    required this.product,
    this.height = 360,
  });

  final BoutiqueProduct product;
  final double height;

  @override
  State<ProductMediaGallery> createState() => _ProductMediaGalleryState();
}

class _ProductMediaGalleryState extends State<ProductMediaGallery> {
  late final PageController _pageController;
  int _index = 0;

  List<String> get _photos {
    final urls = <String>[
      ...widget.product.galleryUrls.where((u) => u.isNotEmpty),
    ];
    final cover = widget.product.imageUrl;
    if (cover != null &&
        cover.isNotEmpty &&
        !urls.contains(cover)) {
      urls.insert(0, cover);
    }
    return urls;
  }

  bool get _hasVideo =>
      (widget.product.videoUrl?.isNotEmpty ?? false);

  int get _pageCount => _photos.isEmpty ? 1 : _photos.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLightbox(int start) {
    if (_photos.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondary) => _Lightbox(
          urls: _photos,
          initialIndex: start,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  if (photos.isEmpty) {
                    return ColoredBox(
                      color: Color.alphaBlend(
                        widget.product.accent.withValues(alpha: 0.14),
                        BoutiqueColors.surface,
                      ),
                      child: Center(
                        child: ProductArt(
                          kind: ProductArt.fromKey(widget.product.art),
                          size: 120,
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _openLightbox(i),
                    child: Hero(
                      tag: 'product-photo-${widget.product.id}-$i',
                      child: Image.network(
                        photos[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, error, stack) => ColoredBox(
                          color: BoutiqueColors.surface,
                          child: ProductArt(
                            kind: ProductArt.fromKey(widget.product.art),
                            size: 120,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (photos.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < photos.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              if (photos.length > 1)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _Chip(label: '${_index + 1} / ${photos.length}'),
                ),
              if (_hasVideo)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _Chip(
                    icon: Icons.videocam_rounded,
                    label: 'ڤیدیۆ',
                  ),
                ),
            ],
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? BoutiqueColors.charcoal
                            : BoutiqueColors.border,
                        width: selected ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(photos[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (_hasVideo) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProductVideoPlayer(url: widget.product.videoUrl!),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVideoPlayer extends StatefulWidget {
  const _ProductVideoPlayer({required this.url});
  final String url;

  @override
  State<_ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<_ProductVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _error;
  bool _ready = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: BoutiqueColors.gold,
          handleColor: BoutiqueColors.goldBright,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
        placeholder: Container(color: const Color(0xFF0E0E0E)),
        autoInitialize: true,
      );
      setState(() {
        _video = controller;
        _chewie = chewie;
        _ready = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'ڤیدیۆکە بار نەبوو');
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ڤیدیۆی بەرهەم',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: BoutiqueColors.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1610), Color(0xFF0A0908)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Vazirmatn'),
        ),
      );
    }
    if (!_ready || _chewie == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: BoutiqueColors.gold,
          ),
        ),
      );
    }
    return Chewie(controller: _chewie!);
  }
}

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              child: Center(
                child: Image.network(widget.urls[i], fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
