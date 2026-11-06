import 'package:flutter/material.dart';
import '../main.dart'; // For DeliveryTheme
import '../services/api_service.dart';
import 'login_screen.dart';
import 'delivery_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    final token = await ApiService.getToken();
    if (mounted) {
      if (token != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DeliveryDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeliveryTheme.forestGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: DeliveryTheme.goldGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: DeliveryTheme.terracotta.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/ronix_logo.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      '🛵',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Roni Courier',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'EXPRESS DISPATCH & LOGISTICS',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: DeliveryTheme.terracotta),
          ],
        ),
      ),
    );
  }
}
