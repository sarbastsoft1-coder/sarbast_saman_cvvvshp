import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/store_components.dart';

/// Sign-in and registration for the boutique.
///
/// Browsing works without an account; this screen is reached when a customer
/// tries to do something that needs one, such as placing an order.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  bool _registering = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Clear a stale error from a previous attempt when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok = _registering
        ? await auth.register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirm.text,
            phone: _phone.text.trim(),
          )
        : await auth.signIn(_email.text.trim(), _password.text);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_registering ? 'دەستپێکردن' : 'چوونەژوورەوە')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 22),
                  Text(
                    _registering
                        ? 'هەژمارێک دروست بکە'
                        : 'بگەڕێوە بۆ هەژمارەکەت',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _registering
                        ? 'هەژمار دروست بکە بۆ کڕین و بەدواداچوونی داواکاری.'
                        : 'بچۆ ناو هەژمارەکەت بۆ بەردەوامبوون لە داواکاریدا.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      height: 1.7,
                      color: BoutiqueColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoniCard(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_registering) ...[
                            TextFormField(
                              key: const Key('auth-name'),
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'ناو',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v ?? '').trim().length < 2
                                  ? 'ناوی تەواو بنووسە'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            key: const Key('auth-email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'ئیمەیل',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'ئیمەیل بنووسە';
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value)) {
                                return 'ئیمەیلی دروست بنووسە';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_registering) ...[
                            TextFormField(
                              key: const Key('auth-phone'),
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'ژمارەی مۆبایل (ئارەزوومەندانە)',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _password,
                            obscureText: _obscure,
                            textDirection: TextDirection.ltr,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'وشەی نهێنی',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? 'پیشاندان' : 'شاردنەوە',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              final value = v ?? '';
                              if (value.isEmpty) return 'وشەی نهێنی بنووسە';
                              if (_registering && value.length < 8) {
                                return 'لانیکەم ٨ پیت پێویستە';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_registering) _submit();
                            },
                          ),

                          if (_registering) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('auth-confirm'),
                              controller: _confirm,
                              obscureText: _obscure,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'دووبارەکردنەوەی وشەی نهێنی',
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              validator: (v) => v != _password.text
                                  ? 'وشەکان وەک یەک نین'
                                  : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],

                          if (auth.error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: auth.error!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GoldButton(
                    key: const Key('auth-submit'),
                    label: auth.busy
                        ? 'چاوەڕێ بکە...'
                        : _registering
                        ? 'دەستپێکردن'
                        : 'چوونەژوورەوە',
                    icon: auth.busy ? null : Icons.login_rounded,
                    onPressed: auth.busy ? null : _submit,
                  ),
                  const SizedBox(height: 10),
                  GhostButton(
                    key: const Key('auth-toggle'),
                    label: _registering
                        ? 'هەژمارت هەیە؟ چوونەژوورەوە'
                        : 'هەژمارت نییە؟ دەستپێکردن',
                    icon: _registering
                        ? Icons.login_rounded
                        : Icons.person_add_alt_1_rounded,
                    onPressed: auth.busy
                        ? null
                        : () => setState(() => _registering = !_registering),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold Ronix coin brand mark.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RonixLogo(size: 72),
      SizedBox(height: 10),
      Text(
        'FAST · TRUSTED · QUALITY',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 8.5,
          letterSpacing: 1.4,
          color: BoutiqueColors.muted,
        ),
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: BoutiqueColors.rose.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BoutiqueColors.rose.withValues(alpha: 0.28)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: BoutiqueColors.rose, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              color: BoutiqueColors.rose,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}
