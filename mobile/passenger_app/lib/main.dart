import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const ShapApp());

class ShapApp extends StatelessWidget {
  const ShapApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Shap',
        debugShowCheckedModeBanner: false,
        theme: ShapTheme.dark,
        home: const SplashScreen(),
      );
}
