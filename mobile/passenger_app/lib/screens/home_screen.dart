import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ride_tier.dart';
import 'ride_request_screen.dart';

/// Home — pick a ride tier. Map would render behind the sheet in production.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shap', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.person), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Placeholder for the live map (google_maps_flutter widget).
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [ShapColors.deep, ShapColors.dark],
                ),
              ),
              child: const Center(
                child: Text('Live map', style: TextStyle(color: Colors.white24, fontSize: 18)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose your ride', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                for (final tier in RideTier.values)
                  _TierCard(
                    tier: tier,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RideRequestScreen(tier: tier)),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final RideTier tier;
  final VoidCallback onTap;
  const _TierCard({required this.tier, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: ShapColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: tier.accent.withOpacity(0.2), child: Icon(tier.icon, color: tier.accent)),
        title: Text(tier.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text(tier.tagline, style: const TextStyle(color: Colors.white54)),
        trailing: tier.isBidding
            ? const Chip(label: Text('Bid', style: TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: ShapColors.primary, padding: EdgeInsets.zero)
            : const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
