import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';
import '../utils/animations.dart' show PressScale;
import '../localization/string_extension.dart';
import 'glass_container.dart' show PillBadge;

class ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final VoidCallback onClaim;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onClaim,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard>
    with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final AnimationController _shimmerCtrl;
  late Animation<double> _progressAnim;

  Color get _accentColor {
    switch (widget.challenge.icon) {
      case '🌱':
        return EarthTheme.sageGreen;
      case '🎨':
        return EarthTheme.terracotta;
      case '🪙':
        return EarthTheme.clayOchre;
      case '⭐':
        return EarthTheme.forestGreen;
      case '♻️':
        return EarthTheme.success;
      default:
        return EarthTheme.sageGreen;
    }
  }

  Color get _bgColor {
    switch (widget.challenge.icon) {
      case '🌱':
        return EarthTheme.sageLight;
      case '🎨':
        return EarthTheme.terracottaSoft;
      case '🪙':
        return EarthTheme.ochreLight;
      case '⭐':
        return EarthTheme.sageLight;
      case '♻️':
        return EarthTheme.successBg;
      default:
        return EarthTheme.sageLight;
    }
  }

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.challenge.progress.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(parent: _progressCtrl, curve: EarthTheme.curveOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _progressCtrl.forward();
        if (widget.challenge.isComplete) _shimmerCtrl.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChallengeCard old) {
    super.didUpdateWidget(old);
    if (old.challenge.progress != widget.challenge.progress) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.challenge.progress.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(parent: _progressCtrl, curve: EarthTheme.curveOut),
      );
      _progressCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
        border: Border.all(
          color: widget.challenge.isComplete
              ? _accentColor.withValues(alpha: 0.30)
              : EarthTheme.borderLight,
          width: widget.challenge.isComplete ? 1.4 : 1,
        ),
        boxShadow: [
          if (widget.challenge.isComplete)
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          else
            ...EarthTheme.subtleShadow,
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, _) {
              final t = _shimmerCtrl.value;
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.challenge.isComplete
                        ? [_accentColor, _accentColor.withValues(alpha: 0.7)]
                        : [_bgColor, _bgColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: widget.challenge.isComplete
                      ? [
                          BoxShadow(
                            color: _accentColor
                                .withValues(alpha: 0.18 + 0.18 * t),
                            blurRadius: 14 + 6 * t,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.challenge.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.challenge.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: EarthTheme.charcoal,
                        ),
                      ),
                    ),
                    if (widget.challenge.isComplete)
                      PillBadge(
                        label: 'DONE',
                        color: _accentColor,
                        textColor: Colors.white,
                        icon: Icons.check_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.challenge.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EarthTheme.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress bar with animated fill + shimmer
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (context, _) {
                    final v = _progressAnim.value;
                    final t = _shimmerCtrl.value;
                    return Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 7,
                                  color: EarthTheme.borderLight,
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 7,
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: v,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _accentColor,
                                            _accentColor.withValues(
                                              alpha: 0.75,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.challenge.isComplete)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: ShaderMask(
                                      blendMode: BlendMode.srcATop,
                                      shaderCallback: (rect) =>
                                          LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(
                                              alpha: 0.55 * (1 - t * 2).abs()),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                        begin: Alignment(
                                          -1.0 + 2 * t,
                                          0,
                                        ),
                                        end: Alignment(
                                          1.0 + 2 * t,
                                          0,
                                        ),
                                      ).createShader(rect),
                                      child: Container(
                                        height: 7,
                                        color: Colors.white
                                            .withValues(alpha: 0.001),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(v * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Reward / Claim button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.challenge.reward} TERRA',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: EarthTheme.clayOchre,
                          ),
                        ),
                      ],
                    ),
                    if (widget.challenge.isComplete)
                      PressScale(
                        onTap: widget.onClaim,
                        scale: 0.94,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                EarthTheme.terracotta,
                                EarthTheme.clayOchre,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: EarthTheme.terracottaGlow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Claim'.tr(context),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
