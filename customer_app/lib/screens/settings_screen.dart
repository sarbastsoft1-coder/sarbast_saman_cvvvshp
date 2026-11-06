import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_selector_sheet.dart';
import '../localization/string_extension.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _biometricLogin = false;
  bool _ecoAlerts = true;

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.get('/auth/profile');
      if (res['status'] == 'success') {
        _nameCtrl.text = res['user']['name'] ?? '';
        _emailCtrl.text = res['user']['email'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final res = await ApiService.post('/profile/update', {
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
      });
      if (mounted) {
        if (res['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: EarthTheme.success,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Profile updated successfully!'.tr(context)),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Update failed')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile'.tr(context))),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthTheme.warmSand,
      appBar: AppBar(
        backgroundColor: EarthTheme.warmSand,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings'.tr(context),
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: EarthTheme.forestGreen,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EarthTheme.terracotta),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Profile'.tr(context)),
                      const SizedBox(height: 10),
                      StaggeredItem(
                        index: 0,
                        child: _accountCard(),
                      ),
                      const SizedBox(height: 10),
                      StaggeredItem(
                        index: 1,
                        child: GradientButton(
                          label: 'Save Changes'.tr(context),
                          icon: Icons.check_rounded,
                          loading: _isSaving,
                          onPressed: _isSaving ? null : _saveProfile,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _sectionHeader('Preferences'.tr(context)),
                      const SizedBox(height: 10),
                      StaggeredItem(
                        index: 2,
                        child: _prefsCard(),
                      ),
                      const SizedBox(height: 28),
                      _sectionHeader('Account'.tr(context)),
                      const SizedBox(height: 10),
                      StaggeredItem(
                        index: 3,
                        child: _accountActions(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: EarthTheme.muted,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _accountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Column(
        children: [
          _Field(
            icon: Icons.person_outline_rounded,
            label: 'Name'.tr(context),
            controller: _nameCtrl,
          ),
          const SizedBox(height: 12),
          _Field(
            icon: Icons.email_outlined,
            label: 'Email'.tr(context),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _prefsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Column(
        children: [
          _languageRow(context),
          _divider(),
          _toggleRow(
            icon: Icons.notifications_active_outlined,
            label: 'Push notifications'.tr(context),
            subtitle: 'Order updates & delivery'.tr(context),
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _divider(),
          _toggleRow(
            icon: Icons.email_outlined,
            label: 'Email notifications'.tr(context),
            subtitle: 'Receipts and newsletters'.tr(context),
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          _divider(),
          _toggleRow(
            icon: Icons.eco_outlined,
            label: 'Eco challenge alerts'.tr(context),
            subtitle: 'New quests and rewards'.tr(context),
            value: _ecoAlerts,
            onChanged: (v) => setState(() => _ecoAlerts = v),
          ),
          _divider(),
          _toggleRow(
            icon: Icons.fingerprint_rounded,
            label: 'Biometric login'.tr(context),
            subtitle: 'Use fingerprint / face ID'.tr(context),
            value: _biometricLogin,
            onChanged: (v) => setState(() => _biometricLogin = v),
          ),
        ],
      ),
    );
  }

  Widget _languageRow(BuildContext context) {
    return PressScale(
      onTap: () => showLanguageSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EarthTheme.ochreLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.language_rounded,
                  color: EarthTheme.clayOchre,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language'.tr(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.charcoal,
                    ),
                  ),
                  Text(
                    LanguageService.instance.currentLanguageName,
                    style: TextStyle(
                      fontSize: 11,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: EarthTheme.warmSandLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EarthTheme.border),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: EarthTheme.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Column(
        children: [
          _actionRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support'.tr(context),
            bgColor: EarthTheme.sageLight,
            iconColor: EarthTheme.sageGreen,
            onTap: () => _showInfo(context, 'Contact support@earthshop.test'),
          ),
          _divider(),
          _actionRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy'.tr(context),
            bgColor: EarthTheme.ochreLight,
            iconColor: EarthTheme.clayOchre,
            onTap: () => _showInfo(context, 'Privacy policy content here'),
          ),
          _divider(),
          _actionRow(
            icon: Icons.logout_rounded,
            label: 'Log Out'.tr(context),
            bgColor: EarthTheme.terracottaSoft,
            iconColor: EarthTheme.terracotta,
            textColor: EarthTheme.terracotta,
            onTap: () async {
              final navigator = Navigator.of(context);
              await ApiService.logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                SharedAxisPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EarthTheme.sageLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Center(child: Icon(icon, color: EarthTheme.forestGreen, size: 19)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.charcoal,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: EarthTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _AnimatedSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 19)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor ?? EarthTheme.charcoal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: EarthTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 64),
      color: EarthTheme.borderLight,
    );
  }

  void _showInfo(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Field extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: EarthTheme.warmSandLight,
        borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
        border: Border.all(color: EarthTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EarthTheme.muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                labelText: label,
                labelStyle: const TextStyle(
                  color: EarthTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
                floatingLabelStyle: const TextStyle(
                  color: EarthTheme.terracotta,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnimatedSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: EarthTheme.dur,
        curve: EarthTheme.curveOut,
        width: 44,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: value ? EarthTheme.success : EarthTheme.border,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: EarthTheme.dur,
          curve: EarthTheme.curveSpring,
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
