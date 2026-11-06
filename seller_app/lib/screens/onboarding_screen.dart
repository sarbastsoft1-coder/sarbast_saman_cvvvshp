import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_transitions.dart';

/// A friendly, animated 3-step wizard that walks new sellers through
/// setting up their studio.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final _storeNameCtrl =
      TextEditingController(text: 'Artisan Studio');
  final _craftCtrl = TextEditingController(text: 'Hand-thrown pottery');
  final _taglineCtrl =
      TextEditingController(text: 'Earth-fired craft, made by hand.');

  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _storeNameCtrl.dispose();
    _craftCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.animateToPage(_page + 1,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page == 0) {
      context.go(AppRoutes.login);
      return;
    }
    _pageCtrl.animateToPage(_page - 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ApiService.post('/seller/store/update', {
        'name': _storeNameCtrl.text.trim(),
        'craft_category': _craftCtrl.text.trim(),
        'tagline': _taglineCtrl.text.trim(),
      });
    } catch (_) {
      // Even if the call fails we still consider the local setup complete.
    }
    await ApiService.setOnboardingComplete();
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _page == 0
        ? _storeNameCtrl.text.trim().isNotEmpty &&
            _craftCtrl.text.trim().isNotEmpty
        : _page == 1
            ? _taglineCtrl.text.trim().isNotEmpty
            : true;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(current: _page, total: 3),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardPage(
                    title: 'Name your studio',
                    subtitle:
                        'Tell buyers who you are. You can change this anytime.',
                    icon: '🏺',
                    child: Column(
                      children: [
                        TextField(
                          controller: _storeNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Workshop / Studio name',
                            prefixIcon: Icon(Icons.storefront_rounded,
                                color: AppColors.terracotta),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _craftCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Craft category',
                            prefixIcon: Icon(Icons.palette_rounded,
                                color: AppColors.terracotta),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  _OnboardPage(
                    title: 'Share your story',
                    subtitle:
                        'A short tagline helps your work stand out on Roni.',
                    icon: '✍️',
                    child: TextField(
                      controller: _taglineCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Studio tagline',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.format_quote_rounded,
                            color: AppColors.terracotta),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _OnboardPage(
                    title: 'Ready to publish',
                    subtitle:
                        'Your studio will appear in the Roni marketplace.',
                    icon: '🚀',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text('🏺',
                                      style: TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _storeNameCtrl.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      _craftCtrl.text,
                                      style: const TextStyle(
                                        color: AppColors.cream,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Studio statement',
                            style: TextStyle(
                              color: AppColors.cream,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '“${_taglineCtrl.text}”',
                              style: const TextStyle(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _back,
                      child: Text(_page == 0 ? 'Sign out' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: _page == 2 ? 'Publish studio' : 'Continue',
                      icon: _page == 2
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      isLoading: _saving,
                      onPressed: !canProceed || _saving ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 5,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.terracotta
                    : AppColors.border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Text(icon, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.forest),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 320),
            child: child,
          ),
        ],
      ),
    );
  }
}