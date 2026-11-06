import 'package:flutter/material.dart';

import '../core/theme/boutique_colors.dart';
import 'roni_motion.dart';

/// Pill-shaped filter / category chip with soft gold selection (HTML chips).
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniPressable(
      scale: .94,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? p.soft : p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? p.brand2 : p.line,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: p.chev.withValues(alpha: .22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? p.brand2 : p.fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
