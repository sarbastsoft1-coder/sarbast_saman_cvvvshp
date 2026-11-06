import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';

class WalletChip extends StatefulWidget {
  final String icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color iconColor;
  final Color? valueColor;
  final VoidCallback onTap;

  const WalletChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.iconColor,
    this.valueColor,
    required this.onTap,
  });

  @override
  State<WalletChip> createState() => _WalletChipState();
}

class _WalletChipState extends State<WalletChip> {
  bool _hover = false;

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
        padding: const EdgeInsets.all(14),
        transform: Matrix4.translationValues(0.0, _hover ? -3.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
          border: Border.all(
            color: _hover ? widget.iconColor.withValues(alpha: 0.35) : EarthTheme.borderLight,
            width: _hover ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: EarthTheme.forestGreen.withValues(
                alpha: _hover ? 0.10 : 0.04,
              ),
              blurRadius: _hover ? 22 : 10,
              offset: Offset(0, _hover ? 10 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 3D-ish icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.bgColor, widget.bgColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: widget.valueColor ?? EarthTheme.forestGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: EarthTheme.durFast,
              turns: _hover ? 0.125 : 0,
              child: Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: EarthTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
