import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/store_components.dart';

/// Phone + OTP demo flow (HTML parity). Completes as a local guest session
/// when no server OTP API exists; still offers email auth as fallback.
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});
  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phone = TextEditingController(text: '750 123 4567');
  final _name = TextEditingController(text: 'سەرهەنگ');
  final _digits = List.generate(6, (_) => TextEditingController());
  bool _sent = false;
  bool _agree = true;
  bool _busy = false;
  String _lang = 'ku';

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    for (final d in _digits) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_agree) return;
    setState(() {
      _sent = true;
      _busy = false;
    });
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final customer = context.read<CustomerProvider>();
    if (_name.text.trim().isNotEmpty) {
      customer.updateName(_name.text.trim());
    }
    final phone = normalizePhone('0${_phone.text.replaceAll(' ', '')}');
    if (validatePhone(phone) == null) {
      customer.updatePhone(phone);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushNamedAndRemoveUntil(BoutiqueRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.of(context).pushReplacementNamed(BoutiqueRoutes.onboard),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(BoutiqueRoutes.home, (_) => false),
            child: const Text(
              'تێپەڕاندن',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w600,
                color: BoutiqueColors.muted,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _LoginWordmark(),
            const SizedBox(height: 20),
            const Text(
              'زمان',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: BoutiqueColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LangChip(
                  label: 'کوردی',
                  selected: _lang == 'ku',
                  onTap: () => setState(() => _lang = 'ku'),
                ),
                _LangChip(
                  label: 'عربي',
                  selected: _lang == 'ar',
                  onTap: () => setState(() => _lang = 'ar'),
                ),
                _LangChip(
                  label: 'English',
                  selected: _lang == 'en',
                  onTap: () => setState(() => _lang = 'en'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              _sent ? 'کۆدەکە بنووسە' : 'ژمارەی مۆبایلەکەت بنووسە',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _sent
                  ? 'کۆدێکی ٦ ژمارەییمان نارد بۆ 0${_phone.text.replaceAll(' ', '')}'
                  : 'کۆدێکی کورتت بۆ دەنێرین. هیچ وشەی نهێنییەکت پێویست نییە.',
              style: const TextStyle(color: BoutiqueColors.muted, fontSize: 13, height: 1.7),
            ),
            const SizedBox(height: 18),
            if (!_sent) ...[
              const Text('ژمارەی مۆبایل', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BoutiqueColors.surface,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                        border: Border.all(color: BoutiqueColors.line2),
                      ),
                      child: const Text('+964', style: TextStyle(fontWeight: FontWeight.w600, color: BoutiqueColors.muted)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: BoutiqueColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('ڕازیم بە یاساکانی بەکارهێنان و سیاسەتی تایبەتی.', style: TextStyle(fontSize: 13.5, height: 1.6)),
              ),
              const SizedBox(height: 8),
              GoldButton(label: 'ناردنی کۆد', onPressed: _agree ? _sendCode : null),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(BoutiqueRoutes.auth),
                child: const Text('چوونەژوورەوە بە ئیمەیڵ', style: TextStyle(color: BoutiqueColors.dustyPink, fontWeight: FontWeight.w700)),
              ),
            ] else ...[
              Row(
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _digits[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: BoutiqueColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Text('ناوت (بۆ گەیاندن)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: BoutiqueColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: _busy ? 'چاوەڕێ بکە…' : 'دڵنیاکردنەوە',
                onPressed: _busy ? null : _verify,
              ),
            ],
            if (context.watch<AuthProvider>().isSignedIn)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: StoreNotice('تۆ پێشتر چوویتە ژوورەوە.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginWordmark extends StatelessWidget {
  const _LoginWordmark();

  @override
  Widget build(BuildContext context) => const RonixLogo(size: 88);
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? BoutiqueColors.softPink : BoutiqueColors.surface,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? BoutiqueColors.dustyPink : BoutiqueColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? BoutiqueColors.dustyPink : BoutiqueColors.charcoal,
          ),
        ),
      ),
    ),
  );
}
