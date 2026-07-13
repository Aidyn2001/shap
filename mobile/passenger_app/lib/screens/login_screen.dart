import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'splash_screen.dart' show ShapLogo;
import 'home_screen.dart';

/// Login screen — mirrors the Shap brand mockup:
/// SA-flag pin logo, "Your ride, Local is Lekker.", phone + password,
/// gradient Log in button, social sign-in, Driver/Customer toggle.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _isDriver = false;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Demo maps phone -> email; wire to a real /auth/login-by-phone in prod.
      await _api.login(_phone.text.trim(), _password.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Purple gradient base (photo backdrop would sit here in production).
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [ShapColors.deep, ShapColors.dark, Color(0xFF2A0A4A)],
              ),
            ),
          ),
          // SA flag ribbon accent at the bottom.
          const Positioned(bottom: 0, left: 0, right: 0, child: _FlagRibbon()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: ShapLogo(size: 72)),
                  const SizedBox(height: 28),
                  const Text('Your ride,',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                  const Text('Local is Lekker.',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                  const SizedBox(height: 10),
                  Row(children: const [
                    Text('Safe. Reliable. ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Mzansi.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ShapColors.neon)),
                  ]),
                  const SizedBox(height: 4),
                  const Text("Wherever you're going.",
                      style: TextStyle(fontSize: 14, color: Colors.white54)),
                  const SizedBox(height: 28),

                  // Phone number
                  TextField(
                    controller: _phone,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      prefixIcon: Icon(Icons.phone, color: ShapColors.neon),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text('🇿🇦', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: ShapColors.neon),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?', style: TextStyle(color: ShapColors.neon)),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),

                  // Gradient Log in button
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [ShapColors.primary, ShapColors.neon]),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('Log in'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(child: Text('or continue with', style: TextStyle(color: Colors.white38))),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata)),
                    const SizedBox(width: 12),
                    Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple)),
                  ]),
                  const SizedBox(height: 18),

                  // Driver / Customer segmented toggle
                  _RoleToggle(
                    isDriver: _isDriver,
                    onChanged: (v) => setState(() => _isDriver = v),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('New here? ', style: TextStyle(color: Colors.white54)),
                      TextButton(onPressed: () {}, child: const Text('Create an account', style: TextStyle(color: ShapColors.neon))),
                    ]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: ShapColors.surface,
          foregroundColor: Colors.white,
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {},
        icon: Icon(icon), label: Text(label),
      );
}

class _RoleToggle extends StatelessWidget {
  final bool isDriver;
  final ValueChanged<bool> onChanged;
  const _RoleToggle({required this.isDriver, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    Widget seg(String text, IconData icon, bool active) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(text == 'Driver'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? ShapColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: ShapColors.surface, borderRadius: BorderRadius.circular(30)),
      child: Row(children: [
        seg('Driver', Icons.person, isDriver),
        const Icon(Icons.swap_horiz, color: Colors.white38, size: 18),
        seg('Customer', Icons.person_outline, !isDriver),
      ]),
    );
  }
}

/// Simple SA-flag colour ribbon at the bottom edge.
class _FlagRibbon extends StatelessWidget {
  const _FlagRibbon();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 10,
        child: Row(children: const [
          Expanded(child: ColoredBox(color: Color(0xFF007A4D))),
          Expanded(child: ColoredBox(color: Color(0xFFFFB612))),
          Expanded(child: ColoredBox(color: Color(0xFFDE3831))),
          Expanded(child: ColoredBox(color: Color(0xFF002395))),
        ]),
      );
}
