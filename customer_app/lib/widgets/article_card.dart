import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _hover = false;

  Color get _tagColor {
    switch (widget.article.tag) {
      case 'Economics':
        return EarthTheme.forestGreen;
      case 'Craft':
        return EarthTheme.terracotta;
      case 'Sustainability':
        return EarthTheme.sageGreen;
      default:
        return EarthTheme.forestGreen;
    }
  }

  Color get _tagBg {
    switch (widget.article.tag) {
      case 'Economics':
        return EarthTheme.mintFaint;
      case 'Craft':
        return EarthTheme.terracottaSoft;
      case 'Sustainability':
        return EarthTheme.sageSoft;
      default:
        return EarthTheme.sageLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: EarthTheme.durFast,
        curve: EarthTheme.curveOut,
        width: 270,
        transform: Matrix4.translationValues(0.0, _hover ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
          border: Border.all(
            color: _hover
                ? _tagColor.withValues(alpha: 0.4)
                : EarthTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: EarthTheme.forestGreen.withValues(
                alpha: _hover ? 0.12 : 0.05,
              ),
              blurRadius: _hover ? 24 : 12,
              offset: Offset(0, _hover ? 14 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with decorative orbs
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _tagBg,
                    _tagColor.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(EarthTheme.radiusMd),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _tagColor.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -12,
                    left: 20,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _tagColor.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: 'article-emoji-${widget.article.id}',
                      child: Text(
                        widget.article.emoji,
                        style: const TextStyle(fontSize: 46),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _tagColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.article.tag.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.article.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EarthTheme.charcoal,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: EarthTheme.mutedSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.article.readTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: EarthTheme.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: EarthTheme.mutedSoft,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.article.author,
                            style: const TextStyle(
                              fontSize: 11,
                              color: EarthTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
