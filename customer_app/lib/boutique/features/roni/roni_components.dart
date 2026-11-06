import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/money.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Canonical unit label for Roni token amounts.
///
/// The wallet is branded "Ronix" across the app (bottom navigation label, home
/// hero), so every numeric token amount in this feature ends with this word.
/// A token amount is never fiat, so it never carries a currency sign.
const String kRonixUnit = 'Ronix';

/// Formats a token amount as a plain grouped number plus the Ronix unit.
///
/// [signed] prefixes positive amounts with "+" (used by the coin history).
String ronixAmount(num value, {bool signed = false}) {
  final amount = value.round();
  final sign = amount < 0 ? '-' : (signed && amount > 0 ? '+' : '');
  return '$sign${Money.group(amount.abs().toString())} $kRonixUnit';
}

/// Formats a fiat amount held in minor units (IQD cents) — "35,000 د.ع".
///
/// Use this for real prices (prize value, donation totals, plan prices).
/// Token amounts must go through [ronixAmount] instead.
String fiatMinor(dynamic minor) => Money.formatIqd(numberOf(minor) / 100);

/// Sorani label for a server-side status / interval token.
///
/// The API returns English enum values (`active`, `pending`, `monthly`, …);
/// showing them raw reads like an untranslated developer screen.
String roniStatusLabel(String? status) =>
    switch (status?.trim().toLowerCase()) {
      'active' => 'چالاک',
      'pending' => 'چاوەڕێ',
      'cancelled' || 'canceled' => 'هەڵوەشێنراوە',
      'completed' || 'complete' => 'تەواو',
      'approved' => 'پشتڕاستکراو',
      'rejected' => 'ردکراوە',
      'paid' => 'دراو',
      'expired' => 'بەسەرچوو',
      'draft' => 'ڕەشنووس',
      'allocated' => 'دابەشکراو',
      'live' => 'ڕاستەوخۆ',
      'ended' => 'کۆتایی هاتوو',
      'closed' => 'داخراو',
      'won' => 'براوە',
      'monthly' => 'مانگانە',
      'yearly' => 'ساڵانە',
      _ => (status == null || status.trim().isEmpty) ? '—' : status.trim(),
    };

/// Sorani label for a loyalty tier returned by the API.
String roniLevelLabel(String? level) =>
    switch (level?.trim().toLowerCase()) {
      'normal' => 'ئاسایی',
      'bronze' => 'برۆنز',
      'silver' => 'زێڕین',
      'gold' => 'ئەڵتین',
      'platinum' => 'پلاتین',
      _ => (level == null || level.trim().isEmpty) ? '—' : level.trim(),
    };

/// Short, readable local timestamp — "2026-11-04 20:01".
String roniDateTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Formats a remaining duration as a countdown clock — "04:12:30",
/// or "2 ڕۆژ 04:12:30" once it passes a day.
String formatCountdown(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final clock =
      '${_two(safe.inHours % 24)}:${_two(safe.inMinutes % 60)}:${_two(safe.inSeconds % 60)}';
  final days = safe.inDays;
  return days > 0 ? '$days ڕۆژ $clock' : clock;
}

/// Live countdown that ticks every second.
///
/// It never runs below zero, stops the timer once the deadline has passed and
/// shows an expired label instead of a frozen "00:00".
class RoniCountdown extends StatefulWidget {
  const RoniCountdown({
    super.key,
    required this.endsAt,
    this.expiredLabel = 'بەسەرچوو',
    this.unknownLabel = '—',
    this.prefix,
    this.style,
    this.textAlign = TextAlign.start,
  });

  /// Deadline of the counted-down event. `null` renders [unknownLabel].
  final DateTime? endsAt;

  /// Shown once [endsAt] has passed.
  final String expiredLabel;

  /// Shown when the event has no known deadline.
  final String unknownLabel;

  /// Optional label rendered before the clock, e.g. 'کاتی بەسەرچوون: '.
  final String? prefix;

  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<RoniCountdown> createState() => _RoniCountdownState();
}

class _RoniCountdownState extends State<RoniCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final end = widget.endsAt;
      if (end != null && !end.isAfter(DateTime.now())) {
        _timer?.cancel();
        _timer = null;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final end = widget.endsAt;
    final style =
        widget.style ??
        BoutiqueTokens.label.copyWith(
          fontFamily: BoutiqueTokens.fontFamily,
          color: p.fg,
          fontWeight: FontWeight.w800,
        );

    if (end == null) {
      return Text(
        widget.prefix == null
            ? widget.unknownLabel
            : '${widget.prefix}${widget.unknownLabel}',
        style: style,
        textAlign: widget.textAlign,
      );
    }

    final remaining = end.difference(DateTime.now());
    final expired = remaining.isNegative || remaining == Duration.zero;
    final clock = expired ? widget.expiredLabel : formatCountdown(remaining);

    final clockWidget = Text(
      clock,
      style: style.copyWith(
        color: expired ? p.sale : style.color,
      ),
      textAlign: widget.textAlign,
      textDirection: expired ? TextDirection.rtl : TextDirection.ltr,
    );

    if (widget.prefix == null) return clockWidget;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.prefix!, style: style.copyWith(color: p.muted)),
        const SizedBox(width: BoutiqueTokens.xs),
        clockWidget,
      ],
    );
  }
}

/// Palette-aware surface used by every card in the Roni feature.
///
/// The shared [RoniCard] defaults to a white surface with a light border,
/// which renders broken in the app's default dark mode. This wrapper resolves
/// both from [RoniPalette] so the feature reads the same in both themes.
class RoniSurfaceCard extends StatelessWidget {
  const RoniSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BoutiqueTokens.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = BoutiqueTokens.radiusMd,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniCard(
      padding: padding,
      onTap: onTap,
      color: color ?? p.card,
      borderColor: borderColor ?? p.line,
      radius: radius,
      shadow: shadow,
      child: child,
    );
  }
}

/// Standard Roni page shell: app bar, pull-to-refresh, loading, error.
class RoniPage extends StatefulWidget {
  const RoniPage({
    super.key,
    required this.title,
    required this.children,
    required this.onRefresh,
    this.loading = false,
    this.error,
    this.requiresAccount = false,
  });
  final String title;
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final bool loading, requiresAccount;
  final String? error;
  @override
  State<RoniPage> createState() => _RoniPageState();
}

class _RoniPageState extends State<RoniPage> {
  /// True until the first successful load, so a refresh keeps the content
  /// visible instead of flashing skeletons over it.
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRefresh();
    });
  }

  @override
  void didUpdateWidget(RoniPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.loading) _firstLoad = false;
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final showSkeleton = _firstLoad && widget.loading;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: widget.loading ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'نوێکردنەوە',
            constraints: const BoxConstraints(
              minWidth: BoutiqueTokens.tapTarget,
              minHeight: BoutiqueTokens.tapTarget,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(BoutiqueTokens.gutter),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (widget.error != null) ...[
                _RoniError(
                  message: widget.error!,
                  onRetry: widget.loading ? null : widget.onRefresh,
                ),
                const SizedBox(height: BoutiqueTokens.sectionGap),
              ],
              if (widget.requiresAccount &&
                  !context.watch<AuthProvider>().isSignedIn)
                RoniSurfaceCard(
                  child: Column(
                    children: [
                      Text(
                        'بۆ بینینی حساب و بەشداریکردن بچۆ ژوورەوە.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted),
                      ),
                      const SizedBox(height: BoutiqueTokens.lg),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, BoutiqueRoutes.auth),
                        child: const Text('چوونەژوورەوە'),
                      ),
                    ],
                  ),
                )
              else if (showSkeleton)
                const _RoniSkeletonList()
              else
                for (var i = 0; i < widget.children.length; i++) ...[
                  RoniFadeSlide(
                    delay: BoutiqueTokens.stagger * i,
                    child: widget.children[i],
                  ),
                  const SizedBox(height: BoutiqueTokens.xl),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error block with a retry affordance.
class _RoniError extends StatelessWidget {
  const _RoniError({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreNotice(message, icon: Icons.error_outline_rounded),
        if (onRetry != null) ...[
          const SizedBox(height: BoutiqueTokens.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('تاقیکردنەوە'),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.fg,
              backgroundColor: p.surface,
              side: BorderSide(color: p.borderStrong),
              minimumSize: const Size(0, BoutiqueTokens.tapTarget),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BoutiqueTokens.radiusSm),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Loading placeholder — shimmering blocks instead of a bare spinner.
class _RoniSkeletonList extends StatelessWidget {
  const _RoniSkeletonList();

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    Widget block(double height) => RoniShimmer(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: p.soft,
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(96),
        const SizedBox(height: BoutiqueTokens.xl),
        block(140),
        const SizedBox(height: BoutiqueTokens.xl),
        block(72),
        const SizedBox(height: BoutiqueTokens.xl),
        block(180),
      ],
    );
  }
}

Future<bool> confirmRoni(
  BuildContext context,
  String title,
  String body,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('پاشگەزبوونەوە'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('پشتڕاستکردنەوە'),
          ),
        ],
      ),
    ) ??
    false;

void roniMessage(BuildContext context, String message) =>
    showRoniToast(context, message);

class RoniMetric extends StatelessWidget {
  const RoniMetric(
    this.label,
    this.value, {
    super.key,
    this.icon = Icons.auto_awesome,
    this.leading,
  });
  final String label, value;
  final IconData icon;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniSurfaceCard(
      child: Row(
        children: [
          leading ?? Icon(icon, size: 32, color: p.brand2),
          const SizedBox(width: BoutiqueTokens.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.sm),
                Text(
                  value,
                  style: BoutiqueTokens.title2.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
