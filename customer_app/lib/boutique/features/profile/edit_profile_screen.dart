import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Full identity sheet: avatar, completion nudge, name / phone / address,
/// sticky save with a clear success moment.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late int _colorIndex;
  late bool _personalized;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<CustomerProvider>();
    _name = TextEditingController(text: c.name);
    _colorIndex = c.avatarColorIndex;
    _personalized = c.avatarPersonalized;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _draftCompletion {
    final c = context.read<CustomerProvider>();
    var score = 0;
    if (_name.text.trim().isNotEmpty) score += 30;
    if (c.displayPhone.isNotEmpty) score += 30;
    if (c.defaultAddress != null) score += 25;
    if (_personalized) score += 15;
    return score.clamp(0, 100);
  }

  String? get _draftHint {
    final pct = _draftCompletion;
    if (pct >= 100) return null;
    if (_name.text.trim().isEmpty) {
      return 'ناوەکەت زیاد بکە تا پڕۆفایلت تەواو بێت';
    }
    final c = context.read<CustomerProvider>();
    if (c.displayPhone.isEmpty) {
      return 'ژمارەی مۆبایل زیاد بکە — بۆ گەیاندن پێویستە';
    }
    if (c.defaultAddress == null) return 'ناونیشانی سەرەکی زیاد بکە';
    if (!_personalized) return 'ڕەنگی وێنەی پڕۆفایل هەڵبژێرە';
    return 'پڕۆفایلت $pct٪ تەواوە';
  }

  Future<void> _pickAvatar() async {
    final picked = await showRoniSheet<(int, bool)>(
      context: context,
      builder: (ctx) => _AvatarSheet(
        selected: _colorIndex,
        personalized: _personalized,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _colorIndex = picked.$1;
      _personalized = picked.$2;
    });
  }

  Future<void> _changePhone() async {
    final customer = context.read<CustomerProvider>();
    final ok = await showRoniSheet<bool>(
      context: context,
      builder: (ctx) => _PhoneOtpSheet(initialPhone: customer.displayPhone),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _save() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      showRoniToast(context, 'تکایە ناو بنووسە');
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    context.read<CustomerProvider>().saveProfile(
      newName: trimmed,
      colorIndex: _colorIndex,
      personalized: _personalized,
    );
    setState(() => _saving = false);
    showRoniToast(context, 'باشە، هەژمارەکەت نوێکرایەوە ✓');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>();
    final p = RoniPalette.of(context);
    final color = Color(
      kAvatarColors[_colorIndex.clamp(0, kAvatarColors.length - 1)],
    );
    final initial = _name.text.trim().isEmpty
        ? 'ب'
        : _name.text.trim().characters.first;
    final phone = customer.displayPhone;
    final addr = customer.defaultAddress;
    final pct = _draftCompletion;
    final hint = _draftHint;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('دەستکاری پڕۆفایل')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                RoniFadeSlide(
                  child: _IdentityHero(
                    initial: initial,
                    color: color,
                    name: _name.text.trim().isEmpty
                        ? 'ناوەکەت لێرە دەردەکەوێت'
                        : _name.text.trim(),
                    onAvatarTap: _pickAvatar,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 14),
                  RoniFadeSlide(
                    delay: const Duration(milliseconds: 40),
                    child: _CompletionNudge(percent: pct, hint: hint),
                  ),
                ],
                const SizedBox(height: 18),
                RoniFadeSlide(
                  delay: const Duration(milliseconds: 70),
                  child: Text(
                    'ناو',
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RoniFadeSlide(
                  delay: const Duration(milliseconds: 80),
                  child: TextField(
                    controller: _name,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بۆ نموونە: شیلان',
                      counterText: '',
                      filled: true,
                      fillColor: p.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BoutiqueTokens.radiusMd,
                        ),
                        borderSide: BorderSide(color: p.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BoutiqueTokens.radiusMd,
                        ),
                        borderSide: BorderSide(color: p.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BoutiqueTokens.radiusMd,
                        ),
                        borderSide: BorderSide(color: p.brand2, width: 1.4),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ئەم ناوە لە هەڵسەنگاندن و داواکارییەکاندا دەردەکەوێت.',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontSize: 12,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 18),
                RoniFadeSlide(
                  delay: const Duration(milliseconds: 110),
                  child: _EditRow(
                    icon: Icons.phone_outlined,
                    label: 'مۆبایل',
                    value: phone.isEmpty ? 'زیادکردن' : phone,
                    valueLtr: phone.isNotEmpty,
                    lockedHint: phone.isNotEmpty ? 'گۆڕین بە OTP' : null,
                    onTap: _changePhone,
                  ),
                ),
                const SizedBox(height: 10),
                RoniFadeSlide(
                  delay: const Duration(milliseconds: 140),
                  child: _EditRow(
                    icon: Icons.location_on_outlined,
                    label: 'ناونیشانی سەرەکی',
                    value: addr == null
                        ? 'زیادکردن'
                        : '${addr.label} · ${addr.address}',
                    onTap: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(BoutiqueRoutes.addresses);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 18),
                RoniFadeSlide(
                  delay: const Duration(milliseconds: 170),
                  child: _CourierPreview(
                    name: _name.text.trim().isEmpty
                        ? 'میوانی ڕۆنی'
                        : _name.text.trim(),
                    phone: phone,
                    address: addr?.address,
                    color: color,
                    initial: initial,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GoldButton(
                label: _saving ? 'پاشەکەوت دەکرێت…' : 'پاشەکەوتکردن',
                icon: _saving ? null : Icons.check_rounded,
                onPressed: _saving ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.initial,
    required this.color,
    required this.name,
    required this.onAvatarTap,
  });

  final String initial;
  final Color color;
  final String name;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            BoutiqueColors.goldWash,
            p.bg,
            BoutiqueColors.softPink.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: BoutiqueTokens.fast,
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.line, width: 1.5),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 16,
                      color: p.brand2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: BoutiqueTokens.fontFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'پەنجە بنێ بۆ گۆڕینی ڕەنگی وێنە',
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: 12,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionNudge extends StatelessWidget {
  const _CompletionNudge({required this.percent, required this.hint});
  final int percent;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: BoutiqueColors.goldWash,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
        border: Border.all(color: BoutiqueColors.logoMark.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: p.brand2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'پڕۆفایلت $percent٪ تەواوە',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: p.fg,
                  ),
                ),
              ),
              Text(
                '$percent٪',
                style: TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: p.brand2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              color: p.brand2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: 12.5,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueLtr = false,
    this.lockedHint,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool valueLtr;
  final String? lockedHint;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: p.brand2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontSize: 12,
                        color: p.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: valueLtr ? TextDirection.ltr : null,
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.fg,
                      ),
                    ),
                    if (lockedHint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lockedHint!,
                        style: TextStyle(
                          fontFamily: BoutiqueTokens.fontFamily,
                          fontSize: 11.5,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourierPreview extends StatelessWidget {
  const _CourierPreview({
    required this.name,
    required this.phone,
    required this.address,
    required this.color,
    required this.initial,
  });

  final String name;
  final String phone;
  final String? address;
  final Color color;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 16, color: p.muted),
              const SizedBox(width: 6),
              Text(
                'وەک کۆریەر و فرۆشیار دەتبینن',
                style: TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: p.fg,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontFamily: BoutiqueTokens.fontFamily,
                          fontSize: 13,
                          color: p.muted,
                        ),
                      ),
                    if (address != null && address!.isNotEmpty)
                      Text(
                        address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: BoutiqueTokens.fontFamily,
                          fontSize: 12.5,
                          color: p.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarSheet extends StatelessWidget {
  const _AvatarSheet({required this.selected, required this.personalized});
  final int selected;
  final bool personalized;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ڕەنگی وێنەی پڕۆفایل',
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'پیتەکانی ناوەکەت لەسەر ئەم ڕەنگە دەردەکەون — وێنە ئارەزوومەندانەیە.',
            style: TextStyle(
              fontFamily: BoutiqueTokens.fontFamily,
              fontSize: 12.5,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < kAvatarColors.length; i++)
                GestureDetector(
                  onTap: () => Navigator.pop(context, (i, true)),
                  child: AnimatedContainer(
                    duration: BoutiqueTokens.fast,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(kAvatarColors[i]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == i && personalized
                            ? BoutiqueColors.goldBright
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (selected == i && personalized)
                          BoxShadow(
                            color: Color(
                              kAvatarColors[i],
                            ).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: selected == i && personalized
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context, (0, false)),
            child: Text(
              'گەڕانەوە بۆ ڕەنگی بنەڕەتی',
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                color: p.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo phone change with OTP (same trust pattern as login).
class _PhoneOtpSheet extends StatefulWidget {
  const _PhoneOtpSheet({required this.initialPhone});
  final String initialPhone;

  @override
  State<_PhoneOtpSheet> createState() => _PhoneOtpSheetState();
}

class _PhoneOtpSheetState extends State<_PhoneOtpSheet> {
  late final TextEditingController _phone;
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final raw = widget.initialPhone.replaceFirst(RegExp(r'^0'), '');
    _phone = TextEditingController(
      text: raw.isEmpty ? '' : raw.replaceAll(' ', ''),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    for (final d in _digits) {
      d.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullPhone {
    final n = normalizePhone(_phone.text);
    if (n.startsWith('07') || n.startsWith('+964') || n.startsWith('964')) {
      return n;
    }
    return '0$n';
  }

  Future<void> _send() async {
    final err = validatePhone(_fullPhone);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _sent = true;
      _busy = false;
    });
    showRoniToast(context, 'کۆد نێردرا · بۆ دیمۆ: ١٢٣٤٥٦');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.first.requestFocus();
    });
  }

  Future<void> _verify() async {
    final code = _digits.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'کۆدی ٦ ژمارەیی بنووسە');
      return;
    }
    // Demo accepts 123456 or any repeated digit run for local trust UX.
    if (code != '123456' && code.split('').toSet().length > 2) {
      setState(() => _error = 'کۆدەکە هەڵەیە · ١٢٣٤٥٦ تاقی بکەرەوە');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.read<CustomerProvider>().updatePhone(_fullPhone);
    showRoniToast(context, 'ژمارەی مۆبایل نوێکرایەوە ✓');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _sent ? 'کۆدەکە بنووسە' : 'گۆڕینی ژمارەی مۆبایل',
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sent
                  ? 'کۆدەکەمان نارد بۆ $_fullPhone'
                  : 'بۆ پاراستنی هەژمارەکەت، گۆڕین بە کۆدی پشتڕاستکردنەوە دەبێت.',
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                fontSize: 12.5,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 16),
            if (!_sent) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                ],
                style: const TextStyle(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  labelText: 'ژمارەی مۆبایل',
                  prefixText: '0  ',
                  prefixStyle: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: p.fg,
                  ),
                  filled: true,
                  fillColor: p.soft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      BoutiqueTokens.radiusMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: p.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ژمارەکەت تەنها بۆ گەیاندن و ئاگادارکردنەوەی داواکارییە.',
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontSize: 11.5,
                        color: p.muted,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: BoutiqueColors.rose,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GoldButton(label: 'ناردنی کۆد', onPressed: _send),
            ] else ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 6; i++)
                      SizedBox(
                        width: 44,
                        child: TextField(
                          controller: _digits[i],
                          focusNode: _focus[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: p.soft,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focus[i + 1].requestFocus();
                            }
                            if (v.isEmpty && i > 0) {
                              _focus[i - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: BoutiqueColors.rose,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GoldButton(
                label: _busy ? 'چاوەڕوان بە…' : 'پشتڕاستکردنەوە',
                onPressed: _busy ? null : _verify,
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _sent = false;
                        _error = null;
                      }),
                child: Text(
                  'گۆڕینی ژمارە',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
