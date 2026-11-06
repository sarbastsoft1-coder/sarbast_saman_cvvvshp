import 'package:flutter/material.dart';

import 'product_art.dart';

/// Circular category icon matching the HTML home strip (illustrated, not Material).
enum CategoryArtKind { all, clothing, bags, kitchen, kids }

class CategoryArt extends StatelessWidget {
  const CategoryArt({super.key, required this.kind, this.size = 56});

  final CategoryArtKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F5F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: switch (kind) {
        CategoryArtKind.all => Icon(
          Icons.grid_view_rounded,
          size: size * 0.42,
          color: const Color(0xFF2B2F36),
        ),
        CategoryArtKind.clothing => ProductArt(
          kind: ProductArtKind.dress,
          size: size * 0.68,
        ),
        CategoryArtKind.bags => ProductArt(
          kind: ProductArtKind.bag,
          size: size * 0.68,
        ),
        CategoryArtKind.kitchen => ProductArt(
          kind: ProductArtKind.kettle,
          size: size * 0.68,
        ),
        CategoryArtKind.kids => ProductArt(
          kind: ProductArtKind.kid,
          size: size * 0.68,
        ),
      },
    );
  }
}
