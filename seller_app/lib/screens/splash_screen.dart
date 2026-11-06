import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotateAnim = Tween<double>(begin: -0.25, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _progressCtrl.forward();
    });

    _decideRoute();
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    final token = await ApiService.getToken();
    final onboarded = await ApiService.isOnboardingComplete();
    if (!mounted) return;

    if (token == null) {
      context.go(AppRoutes.login);
    } else if (!onboarded) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: const BoxDecoration(gradient: AppColors.auroraGradient),
          ),
          // Floating orbs
          const Positioned.fill(
            child: FloatingOrbsBackground(seed: 11),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _rotateAnim.value,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: _AnimatedEmblem(progress: _progressCtrl),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _fadeAnim,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _fadeAnim.value,
                        child: Column(
                          children: [
                            const Text(
                              'Roni',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RONI SELLER STUDIO',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 4),
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, _) {
                      return ProgressRing(
                        progress: _progressCtrl.value,
                        color: AppColors.gold,
                        trackColor: Colors.white12,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing your workspace…',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEmblem extends StatelessWidget {
  const _AnimatedEmblem({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.terracotta.withValues(alpha: 0.45),
            blurRadius: 38,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/ronix_logo.png',
            width: 76,
            height: 76,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'R',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}