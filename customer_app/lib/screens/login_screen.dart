import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import 'main_shell.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_selector_sheet.dart';
import '../localization/string_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'customer@test.com');
  final _passwordCtrl = TextEditingController(text: 'password');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: EarthTheme.curveOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_fade);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      SharedAxisPageRoute(
        builder: (_) => const MainShell(),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/auth/login', {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });

      if (response['status'] == 'success') {
        await ApiService.setToken(response['token']);
        if (!mounted) return;
        _continueAsGuest();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server offline. Continue as Guest?'),
          action: SnackBarAction(
            label: 'Enter Demo',
            textColor: EarthTheme.goldenGlow,
            onPressed: _continueAsGuest,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE3ECE5),
                  Color(0xFFF7EBDD),
                  Color(0xFFF9F7F2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _buildBgOrb(
            top: -100,
            right: -90,
            size: 320,
            colors: const [EarthTheme.sageGreen, EarthTheme.mint],
            speed: 0.7,
          ),
          _buildBgOrb(
            bottom: -120,
            left: -120,
            size: 360,
            colors: const [EarthTheme.clayOchre, EarthTheme.goldenGlow],
            speed: 0.5,
          ),
          _buildBgOrb(
            top: 100,
            left: -40,
            size: 140,
            colors: const [EarthTheme.terracotta, EarthTheme.coral],
            speed: 1.0,
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: GlassContainer(
                        padding: const EdgeInsets.fromLTRB(26, 32, 26, 26),
                        radius: 28,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.4,
                        ),
                        shadow: [
                          BoxShadow(
                            color: EarthTheme.forestGreen
                                .withValues(alpha: 0.10),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top row: Logo + Language switch button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          EarthTheme.forestGreen,
                                          EarthTheme.sageGreen,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: EarthTheme.forestGreen
                                              .withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🌿',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                                  PressScale(
                                    onTap: () => showLanguageSheet(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EarthTheme.warmSandLight,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: EarthTheme.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            LanguageService.instance.languageCode == 'ckb'
                                                ? '☀️'
                                                : LanguageService.instance.languageCode == 'ar'
                                                    ? '🌙'
                                                    : '🌍',
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            LanguageService.instance
                                                .currentLanguageName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: EarthTheme.charcoal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              Text(
                                'Welcome Back'.tr(context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: EarthTheme.forestGreen,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in to continue your artisan journey'.tr(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EarthTheme.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email
                              _AnimatedField(
                                focused: _emailFocused,
                                onFocus: (v) =>
                                    setState(() => _emailFocused = v),
                                icon: Icons.email_outlined,
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Email address'.tr(context),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                    fillColor: Colors.transparent,
                                    filled: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: EarthTheme.charcoal,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter your email'.tr(context);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Password
                              _AnimatedField(
                                focused: _passFocused,
                                onFocus: (v) =>
                                    setState(() => _passFocused = v),
                                icon: Icons.lock_outline_rounded,
                                child: TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    hintText: 'Password'.tr(context),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 16),
                                    fillColor: Colors.transparent,
                                    filled: true,
                                    suffixIcon: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      child: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: EarthTheme.muted,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: EarthTheme.charcoal,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password'.tr(context);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reset link sent (demo).',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot password?'.tr(context),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: EarthTheme.terracotta,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              GradientButton(
                                label: 'Sign In'.tr(context),
                                icon: Icons.arrow_forward_rounded,
                                loading: _isLoading,
                                onPressed: _login,
                              ),
                              const SizedBox(height: 10),

                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.explore_outlined,
                                  size: 18,
                                  color: EarthTheme.forestGreen,
                                ),
                                label: Text(
                                  'Explore as Guest (Offline Demo)'.tr(context),
                                  style: const TextStyle(
                                    color: EarthTheme.forestGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  side: const BorderSide(
                                    color: EarthTheme.forestGreen,
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      EarthTheme.radiusSm,
                                    ),
                                  ),
                                ),
                                onPressed: _continueAsGuest,
                              ),
                              const SizedBox(height: 20),

                              // Divider with text
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: EarthTheme.borderLight,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH'.tr(context),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: EarthTheme.mutedSoft,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: EarthTheme.borderLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.alternate_email_rounded,
                                      label: 'Google',
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Connecting via Google Demo...'),
                                          ),
                                        );
                                        _continueAsGuest();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.apple_rounded,
                                      label: 'Apple',
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Connecting via Apple Demo...'),
                                          ),
                                        );
                                        _continueAsGuest();
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Creating demo session for you...'),
                                    ),
                                  );
                                  _continueAsGuest();
                                },
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: EarthTheme.muted,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Don't have an account? ".tr(context),
                                      ),
                                      TextSpan(
                                        text: 'Sign up (Quick Access)'.tr(context),
                                        style: const TextStyle(
                                          color: EarthTheme.terracotta,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgOrb({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required List<Color> colors,
    required double speed,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: FloatingElement(
        amplitude: 18,
        speed: speed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.25),
                blurRadius: 60,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  final bool focused;
  final ValueChanged<bool> onFocus;
  final IconData icon;
  final Widget child;

  const _AnimatedField({
    required this.focused,
    required this.onFocus,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocus,
      child: AnimatedContainer(
        duration: EarthTheme.durFast,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: focused ? Colors.white : EarthTheme.warmSandLight,
          borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
          border: Border.all(
            color: focused ? EarthTheme.terracotta : EarthTheme.border,
            width: focused ? 1.6 : 1,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: EarthTheme.terracotta.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: focused ? EarthTheme.terracotta : EarthTheme.muted,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
          border: Border.all(color: EarthTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: EarthTheme.charcoal),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: EarthTheme.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
