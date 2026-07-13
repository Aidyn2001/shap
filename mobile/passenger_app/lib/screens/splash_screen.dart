import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [ShapColors.deep, ShapColors.dark],
          ),
        ),
        child: const Center(child: ShapLogo(size: 96)),
      ),
    );
  }
}

/// SA-flag pin + car mark and "Shap" wordmark.
class ShapLogo extends StatelessWidget {
  final double size;
  const ShapLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.location_on, size: size, color: ShapColors.neon),
            Icon(Icons.directions_car, size: size * 0.42, color: Colors.white),
          ],
        ),
        const SizedBox(height: 4),
        Text('Shap',
            style: TextStyle(
              fontSize: size * 0.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            )),
      ],
    );
  }
}
