import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import '../services/api_service.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _auraCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOut,
    );

    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 2700), () async {
      final token = await ApiService.getToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              token != null ? const MainShell() : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            return FadeTransition(opacity: fade, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _progressCtrl.dispose();
    _auraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: EarthTheme.splashGradient)),
          // Floating gradient orbs
          Positioned(
            top: -80,
            left: -60,
            child: FloatingElement(
              amplitude: 18,
              speed: 0.7,
              child: GradientOrb(
                size: 280,
                gradient: const LinearGradient(
                  colors: [Color(0xFFC86D51), Color(0xFFD29054)],
                ),
                opacity: 0.45,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: FloatingElement(
              amplitude: 22,
              speed: 0.9,
              rotate: 0.05,
              child: GradientOrb(
                size: 320,
                gradient: const LinearGradient(
                  colors: [Color(0xFF748E7B), Color(0xFFB8D4C2)],
                ),
                opacity: 0.35,
              ),
            ),
          ),
          // Floating leaves
          ..._buildLeaves(),

          // Center logo + content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _auraCtrl]),
                  builder: (context, _) {
                    final auraT = _auraCtrl.value;
                    return ScaleTransition(
                      scale: _scaleAnim,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer aura
                          Container(
                            width: 160 + auraT * 30,
                            height: 160 + auraT * 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  EarthTheme.terracotta
                                      .withValues(alpha: 0.35 * (1 - auraT)),
                                  EarthTheme.terracotta.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  EarthTheme.terracotta.withValues(alpha: 0.25),
                                  EarthTheme.terracotta.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          // Logo container
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: EarthTheme.terracotta.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: EarthTheme.terracotta.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: EarthTheme.terracotta.withValues(alpha: 0.3),
                                  blurRadius: 30 + auraT * 20,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: FloatingElement(
                                amplitude: 4,
                                speed: 1.4,
                                rotate: 0.04,
                                sway: false,
                                child: const Text(
                                  '🌿',
                                  style: TextStyle(fontSize: 52),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Title with shimmer
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Shimmer(
                    duration: const Duration(milliseconds: 2400),
                    child: const Text(
                      'EarthShop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: const Text(
                    'ARTISAN  •  TOKEN  •  ECO',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 56),

                // Progress
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    width: 180,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.10),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  EarthTheme.terracottaLight,
                                ),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🌱',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cultivating your experience...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  List<Widget> _buildLeaves() {
    final rnd = math.Random(42);
    final emojis = ['🍃', '🌿', '🌱', '🍂', '☘️'];
    return List.generate(14, (i) {
      final size = 16 + rnd.nextDouble() * 22;
      final left = rnd.nextDouble();
      final top = rnd.nextDouble();
      final speed = 0.5 + rnd.nextDouble() * 1.5;
      return Positioned(
        left: left * MediaQuery.of(context).size.width,
        top: top * MediaQuery.of(context).size.height,
        child: FloatingElement(
          amplitude: 12 + rnd.nextDouble() * 14,
          speed: speed,
          rotate: (rnd.nextBool() ? 1 : -1) * (0.08 + rnd.nextDouble() * 0.08),
          sway: true,
          child: Opacity(
            opacity: 0.55,
            child: Text(
              emojis[i % emojis.length],
              style: TextStyle(fontSize: size),
            ),
          ),
        ),
      );
    });
  }
}
