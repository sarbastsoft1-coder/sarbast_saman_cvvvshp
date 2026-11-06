import 'package:flutter/material.dart';
import '../core/constants/money.dart';
import '../core/shop_department.dart';
import '../core/theme/boutique_colors.dart';
import '../core/theme/boutique_tokens.dart';

/// White rounded surface used for nearly every block in the Roni layout,
/// enhanced with subtle interactive scale micro-interactions on tap.
class RoniCard extends StatefulWidget {
  const RoniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.radius = BoutiqueTokens.radiusLg,
    this.borderColor,
    this.shadow = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Surface colour. Defaults to the palette's card colour, so a card follows
  /// the active light/dark theme instead of baking in a light literal.
  final Color? color;
  final double radius;

  /// Hairline border colour. Defaults to the palette's line colour.
  final Color? borderColor;
  final bool shadow;

  @override
  State<RoniCard> createState() => _RoniCardState();
}

class _RoniCardState extends State<RoniCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final content = AnimatedContainer(
      duration: BoutiqueTokens.fast,
      curve: BoutiqueTokens.curveStandard,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? p.card,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.borderColor ?? p.line),
        boxShadow: widget.shadow
            ? (_pressed ? null : BoutiqueTokens.shadowCard(p))
            : null,
      ),
      // ListTile paints its ink on the nearest Material. Without one inside
      // this decorated box, Flutter reports the splash as invisible.
      child: Material(type: MaterialType.transparency, child: widget.child),
    );
    if (widget.onTap == null) return content;
    return AnimatedScale(
      scale: _pressed ? BoutiqueTokens.pressScale : 1.0,
      duration: BoutiqueTokens.fast,
      curve: BoutiqueTokens.curveStandard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (_pressed != highlighted && mounted) {
              setState(() => _pressed = highlighted);
            }
          },
          borderRadius: BorderRadius.circular(widget.radius),
          child: content,
        ),
      ),
    );
  }
}

/// Primary call to action — solid HTML green (class name kept for call sites).
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 52,
    this.radius = BoutiqueTokens.radiusMd,
    this.subtitle,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final double radius;

  /// Optional second line rendered under [label] (e.g. a running total).
  final String? subtitle;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final enabled = widget.onPressed != null;
    final child = AnimatedContainer(
      duration: BoutiqueTokens.fast,
      curve: BoutiqueTokens.curveStandard,
      decoration: BoxDecoration(
        color: enabled ? null : p.line,
        gradient: enabled ? BoutiqueColors.goldGradient : null,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: SizedBox(
        height: widget.height,
        width: widget.expand ? double.infinity : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.expand ? 18 : 18),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: enabled ? BoutiqueColors.onGold : p.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? BoutiqueColors.onGold
                            : p.onSurfaceVariant,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: BoutiqueTokens.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? BoutiqueColors.onGold.withValues(alpha: .85)
                              : p.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final tap = AnimatedScale(
      scale: (_pressed && enabled) ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: enabled
              ? (highlighted) {
                  if (_pressed != highlighted && mounted) {
                    setState(() => _pressed = highlighted);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(widget.radius),
          child: child,
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.subtitle == null
          ? widget.label
          : '${widget.label}, ${widget.subtitle}',
      child: tap,
    );
  }
}

/// Outlined secondary action, used beside [GoldButton].
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 54,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.fg,
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}

/// Sliding Men / Women control used on home, catalog, and registration.
class GenderShopSwitch extends StatelessWidget {
  const GenderShopSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final ShopDepartment value;
  final ValueChanged<ShopDepartment> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      height: compact ? 40 : 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusSm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          final isFemale = value == ShopDepartment.female;
          return Stack(
            children: [
              AnimatedAlign(
                duration: BoutiqueTokens.emphasized,
                curve: BoutiqueTokens.curveStandard,
                alignment: isFemale
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Container(
                  width: tabWidth,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(
                      BoutiqueTokens.radiusXs + 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.fg.withValues(alpha: 0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _GenderTab(
                    department: ShopDepartment.female,
                    selected: isFemale,
                    onTap: () => onChanged(ShopDepartment.female),
                  ),
                  _GenderTab(
                    department: ShopDepartment.male,
                    selected: !isFemale,
                    onTap: () => onChanged(ShopDepartment.male),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GenderTab extends StatelessWidget {
  const _GenderTab({
    required this.department,
    required this.selected,
    required this.onTap,
  });

  final ShopDepartment department;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final color = selected ? p.fg : p.muted;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXs + 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(department.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                department.label,
                style: TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two large cards for picking male/female during registration.
class GenderChoiceCards extends StatelessWidget {
  const GenderChoiceCards({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ShopDepartment? value;
  final ValueChanged<ShopDepartment> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderChoiceCard(
            department: ShopDepartment.female,
            selected: value == ShopDepartment.female,
            onTap: () => onChanged(ShopDepartment.female),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GenderChoiceCard(
            department: ShopDepartment.male,
            selected: value == ShopDepartment.male,
            onTap: () => onChanged(ShopDepartment.male),
          ),
        ),
      ],
    );
  }
}

class _GenderChoiceCard extends StatelessWidget {
  const _GenderChoiceCard({
    required this.department,
    required this.selected,
    required this.onTap,
  });

  final ShopDepartment department;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusLg),
        child: AnimatedContainer(
          duration: BoutiqueTokens.base,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? p.saleSoft : p.card,
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
            border: Border.all(
              color: selected ? p.brand2 : p.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                department.icon,
                size: 28,
                color: selected ? p.brand2 : p.fg,
              ),
              const SizedBox(height: 8),
              Text(
                department.label,
                style: TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured order-status pill: Processing / Shipped / Delivered / Cancelled.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final (fg, bg) = switch (tone) {
      StatusTone.processing => (p.statusProcessing, p.statusProcessingWash),
      StatusTone.shipped => (p.statusShipped, p.statusShippedWash),
      StatusTone.delivered => (p.statusDelivered, p.statusDeliveredWash),
      StatusTone.cancelled => (p.statusCancelled, p.statusCancelledWash),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: BoutiqueTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

enum StatusTone { processing, shipped, delivered, cancelled }

/// "Today's Deals" style header with a trailing action link.
class RoniSectionHeader extends StatelessWidget {
  const RoniSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 10),
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: p.fg),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: p.brand2,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.brand2,
                    ),
                  ),
                  // "See all" is a forward affordance: in this RTL app it must
                  // point left, which `chevron_right` produces once Flutter
                  // mirrors it for the ambient text direction.
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded search field matching the mockup's pill search bar.
class RoniSearchField extends StatelessWidget {
  const RoniSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.autofocus = false,
    this.trailing,
  });
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool autofocus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: BoutiqueTokens.fontFamily,
          fontSize: 15,
          color: p.fg,
        ),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          hintStyle: TextStyle(color: p.muted),
          prefixIcon: Icon(Icons.search_rounded, size: 22, color: p.muted),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: trailing ?? _defaultSuffix(p),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          filled: true,
          fillColor: p.surfaceSunken,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
            borderSide: BorderSide(color: p.brand2, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget? _defaultSuffix(RoniPalette p) => onFilterTap == null
      ? null
      : IconButton(
          onPressed: onFilterTap,
          tooltip: 'فیلتەر',
          iconSize: 20,
          icon: Icon(Icons.tune_rounded, color: p.fg),
        );
}

/// Small round icon button used across the Roni top bars.
class RoniIconButton extends StatelessWidget {
  const RoniIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badgeCount = 0,
    this.tooltip,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final int badgeCount;
  final String? tooltip;

  /// Icon colour. Defaults to the palette's primary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 21,
          constraints: const BoxConstraints(
            minWidth: BoutiqueTokens.tapTarget,
            minHeight: BoutiqueTokens.tapTarget,
          ),
          style: IconButton.styleFrom(
            backgroundColor: p.surface,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, color: color ?? p.fg),
        ),
        if (badgeCount > 0)
          PositionedDirectional(
            top: 2,
            end: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(color: p.sale, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StorePanel extends StatelessWidget {
  const StorePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BoutiqueTokens.xl),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXl),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

class StoreNotice extends StatelessWidget {
  const StoreNotice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(BoutiqueTokens.xl),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.brand2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                fontSize: 12,
                height: 1.7,
                color: p.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreEmpty extends StatelessWidget {
  const StoreEmpty({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: p.brand2),
            ),
            const SizedBox(height: BoutiqueTokens.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: p.fg),
            ),
            const SizedBox(height: BoutiqueTokens.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: p.muted),
            ),
            if (action != null) ...[
              const SizedBox(height: BoutiqueTokens.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder used while a list or grid is loading.
///
/// A bare spinner tells the customer nothing about what is about to appear; a
/// skeleton shows the shape of the incoming content and stops the layout from
/// jumping when the real data lands.
class RoniSkeleton extends StatefulWidget {
  const RoniSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = BoutiqueTokens.radiusSm,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<RoniSkeleton> createState() => _RoniSkeletonState();
}

class _RoniSkeletonState extends State<RoniSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BoutiqueTokens.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [p.surfaceSunken, p.line, p.surfaceSunken],
            ),
          ),
        );
      },
    );
  }
}

/// A vertical stack of skeleton rows, for loading a list.
class RoniSkeletonList extends StatelessWidget {
  const RoniSkeletonList({super.key, this.count = 4, this.itemHeight = 76});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(BoutiqueTokens.gutter),
    itemCount: count,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    separatorBuilder: (_, __) => const SizedBox(height: BoutiqueTokens.lg),
    itemBuilder: (context, index) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoniSkeleton(width: 64, height: 64, radius: BoutiqueTokens.radiusMd),
        const SizedBox(width: BoutiqueTokens.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoniSkeleton(width: double.infinity, height: 14),
              const SizedBox(height: BoutiqueTokens.sm),
              RoniSkeleton(width: 120, height: 12),
              const SizedBox(height: BoutiqueTokens.sm),
              RoniSkeleton(width: 70, height: 16),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Quantity stepper with comfortable, always-visible tap targets.
class RoniQuantityStepper extends StatelessWidget {
  const RoniQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.size = BoutiqueTokens.tapTarget,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'کەمێک',
            size: size,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.fg,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'زیادی بکە',
            size: size,
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? p.onSurfaceVariant : p.fg,
          ),
        ),
      ),
    );
  }
}

/// Star rating with the score and review count in one readable line.
class RoniRatingRow extends StatelessWidget {
  const RoniRatingRow({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 15,
    this.showCount = true,
  });

  final double rating;
  final int? reviewCount;
  final double size;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The score is a Latin-number run: keep it LTR so "4.8" never
        // renders as "8.4" inside the RTL paragraph.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: p.fg,
            ),
          ),
        ),
        const SizedBox(width: BoutiqueTokens.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final filled = index < rating.round();
            return Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: p.gold,
            );
          }),
        ),
        if (showCount && reviewCount != null) ...[
          const SizedBox(width: BoutiqueTokens.xs),
          Text(
            '($reviewCount)',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: size - 2,
              fontWeight: FontWeight.w500,
              color: p.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Trust signals — the small reassurance row that sits under a product price.
class RoniTrustRow extends StatelessWidget {
  const RoniTrustRow({super.key, required this.items, this.iconSize = 18});

  /// Each entry is an icon and a short label, e.g. `(Icons.local_shipping, 'گەیاندنی خێرا')`.
  final List<(IconData, String)> items;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: BoutiqueTokens.md),
              color: p.line,
            ),
          Expanded(
            child: Column(
              children: [
                Icon(items[i].$1, size: iconSize, color: p.brand2),
                const SizedBox(height: BoutiqueTokens.xs),
                Text(
                  items[i].$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A price rendered the same way everywhere in the app.
class RoniPriceText extends StatelessWidget {
  const RoniPriceText({
    super.key,
    required this.amount,
    required this.currency,
    this.originalAmount,
    this.large = false,
    this.color,
  });

  final num amount;
  final String currency;
  final num? originalAmount;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final style = (large ? BoutiqueTokens.priceLarge : BoutiqueTokens.price)
        .copyWith(color: color ?? p.fg);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Money.format(amount, currency: currency),
          style: style,
          textDirection: TextDirection.ltr,
        ),
        if (originalAmount != null) ...[
          const SizedBox(width: BoutiqueTokens.md),
          Text(
            Money.format(originalAmount!, currency: currency),
            style: BoutiqueTokens.priceStrike.copyWith(color: p.muted),
            textDirection: TextDirection.ltr,
          ),
        ],
      ],
    );
  }
}

/// Standard screen header: title on the start side, a back affordance and
/// optional trailing actions.
class RoniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RoniAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.subtitle,
    this.showDivider = true,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? subtitle;
  final bool showDivider;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: p.bg,
        border: showDivider ? Border(bottom: BorderSide(color: p.line)) : null,
      ),
      child: Row(
        children: [
          if (onBack != null)
            Semantics(
              button: true,
              label: 'گەڕانەوە',
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(BoutiqueTokens.radiusSm),
                child: const SizedBox(
                  width: BoutiqueTokens.tapTarget,
                  height: BoutiqueTokens.tapTarget,
                  // Back is a start-side affordance in RTL and must point
                  // right; `arrow_back` is mirrored by Flutter to do exactly
                  // that.
                  child: Icon(Icons.arrow_back_rounded, size: 22),
                ),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BoutiqueTokens.title3.copyWith(color: p.fg),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BoutiqueTokens.caption.copyWith(color: p.muted),
                  ),
              ],
            ),
          ),
          ...actions,
          const SizedBox(width: BoutiqueTokens.sm),
        ],
      ),
    );
  }
}

/// Error state with a retry affordance.
class RoniErrorState extends StatelessWidget {
  const RoniErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'هەڵەیەک ڕوویدا',
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BoutiqueTokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.saleSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 32, color: p.sale),
            ),
            const SizedBox(height: BoutiqueTokens.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BoutiqueTokens.title3.copyWith(color: p.fg),
            ),
            const SizedBox(height: BoutiqueTokens.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BoutiqueTokens.bodySmall.copyWith(color: p.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BoutiqueTokens.xxl),
              GhostButton(
                label: 'دووبارە هەوڵ بدەوە',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expand: false,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
