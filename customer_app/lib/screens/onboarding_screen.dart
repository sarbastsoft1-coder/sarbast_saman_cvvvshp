import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardSlide> _slides = [
    _OnboardSlide(
      icon: '🛍️',
      title: 'Discover Artisan Goods',
      description:
          'Explore hand-crafted ceramics, organic teas, woven linens, and mountain harvests from verified eco-artisans.',
      accent: EarthTheme.sageGreen,
      bg: EarthTheme.mintFaint,
      orbs: [
        _OrbData(-60, -40, 0.5, _OrbKind.sage),
        _OrbData(40, 60, 0.4, _OrbKind.gold),
      ],
    ),
    _OnboardSlide(
      icon: '🪙',
      title: 'Trade Terra Tokens',
      description:
          'Exchange Terra tokens on our peer-to-peer marketplace. Buy, sell, and earn with zero platform fees.',
      accent: EarthTheme.clayOchre,
      bg: EarthTheme.ochreLight,
      orbs: [
        _OrbData(60, -50, 0.45, _OrbKind.gold),
        _OrbData(-50, 50, 0.35, _OrbKind.terra),
      ],
    ),
    _OnboardSlide(
      icon: '🏆',
      title: 'Complete Eco Challenges',
      description:
          'Earn rewards by supporting sustainable practices. Complete challenges, earn badges, and collect Terra tokens.',
      accent: EarthTheme.terracotta,
      bg: EarthTheme.terracottaSoft,
      orbs: [
        _OrbData(-50, -50, 0.5, _OrbKind.terra),
        _OrbData(50, 50, 0.4, _OrbKind.sage),
      ],
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      SharedAxisPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background orbs
          ..._buildBgOrbs(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _goToLogin,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: EarthTheme.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemCount: _slides.length,
                          itemBuilder: (context, i) {
                            final slide = _slides[i];
                            return _OnboardSlideView(slide: slide);
                          },
                        ),
                      ),

                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = _currentPage == i;
                          return AnimatedContainer(
                            duration: EarthTheme.dur,
                            curve: EarthTheme.curveSpring,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? EarthTheme.terracotta
                                  : EarthTheme.border,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: active
                                  ? EarthTheme.terracottaGlow
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Action button
                      GradientButton(
                        label: _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        icon: _currentPage == _slides.length - 1
                            ? Icons.arrow_forward_rounded
                            : null,
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 420),
                              curve: EarthTheme.curveInOut,
                            );
                          } else {
                            _goToLogin();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBgOrbs() {
    return [
      Positioned(
        top: -100,
        right: -80,
        child: FloatingElement(
          amplitude: 20,
          speed: 0.8,
          child: GradientOrb(
            size: 280,
            gradient: const LinearGradient(
              colors: [Color(0xFFE3ECE5), Color(0xFFF7EBDD)],
            ),
            opacity: 0.7,
          ),
        ),
      ),
      Positioned(
        bottom: -120,
        left: -100,
        child: FloatingElement(
          amplitude: 24,
          speed: 0.6,
          child: GradientOrb(
            size: 320,
            gradient: const LinearGradient(
              colors: [Color(0xFFF7EBDD), Color(0xFFE3ECE5)],
            ),
            opacity: 0.5,
          ),
        ),
      ),
    ];
  }
}

enum _OrbKind { sage, gold, terra }

extension on _OrbKind {
  List<Color> get colors {
    switch (this) {
      case _OrbKind.sage:
        return const [Color(0xFF748E7B), Color(0xFFB8D4C2)];
      case _OrbKind.gold:
        return const [Color(0xFFD29054), Color(0xFFF5C16C)];
      case _OrbKind.terra:
        return const [Color(0xFFC86D51), Color(0xFFE89679)];
    }
  }
}

class _OrbData {
  final double dx, dy, opacity;
  final _OrbKind kind;
  const _OrbData(this.dx, this.dy, this.opacity, this.kind);
}

class _OnboardSlide {
  final String icon;
  final String title;
  final String description;
  final Color accent;
  final Color bg;
  final List<_OrbData> orbs;

  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.bg,
    required this.orbs,
  });
}

class _OnboardSlideView extends StatelessWidget {
  final _OnboardSlide slide;
  const _OnboardSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Decorative orbs inside the slide
            ...slide.orbs.map(
              (o) => Transform.translate(
                offset: Offset(o.dx, o.dy),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: o.kind.colors
                          .map((c) => c.withValues(alpha: o.opacity))
                          .toList(),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: o.kind.colors.first.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Main illustration circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: slide.bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: slide.accent.withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.accent.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: FloatingElement(
                  amplitude: 6,
                  speed: 1.2,
                  rotate: 0.04,
                  sway: false,
                  child: Text(
                    slide.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),

        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: EarthTheme.forestGreen,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: EarthTheme.slate,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
