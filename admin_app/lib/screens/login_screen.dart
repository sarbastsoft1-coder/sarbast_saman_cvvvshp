import 'package:flutter/material.dart';
import '../main.dart'; // For AdminTheme
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_animations.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@earthshop.test');
  final _passwordCtrl = TextEditingController(text: 'password');
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/auth/login', {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });

      if (response['status'] == 'success') {
        final user = response['user'];
        final role = user is Map ? user['role']?.toString() : null;
        if (role != 'admin') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This console is only for an admin account.'),
            ),
          );
          return;
        }
        await ApiService.setToken(response['token']);
        if (!mounted) return;
        // Only poll for this account's feed once the token is in place.
        NotificationProvider.instance.startPolling();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.warmSand,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: FadeSlideIn(
            child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AdminTheme.goldGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AdminTheme.terracotta.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/ronix_logo.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text(
                              '🏛️',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Admin Portal Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Roni executive control and system monitoring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: Color(0xFF6B5D4D),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Log In'),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
