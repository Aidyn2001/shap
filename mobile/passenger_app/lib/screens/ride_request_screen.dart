import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ride_tier.dart';

/// Ride request. For Ola, passenger suggests a price (bidding).
/// For Mojo/Grand, shows the fixed estimate and a Confirm button.
class RideRequestScreen extends StatefulWidget {
  final RideTier tier;
  const RideRequestScreen({super.key, required this.tier});
  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _offer = TextEditingController();
  // Demo estimate; real value comes from ApiService.quote(...).
  double get estimate => switch (widget.tier) {
        RideTier.ola => 68, RideTier.mojo => 120, RideTier.grand => 340,
      };

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    return Scaffold(
      appBar: AppBar(title: Text(t.label)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(Icons.my_location, 'Pickup', 'Current location'),
            const SizedBox(height: 12),
            _field(Icons.location_on, 'Drop-off', 'Where to?'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShapColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t.isBidding ? 'Suggested fare' : 'Estimated fare', style: const TextStyle(color: Colors.white70)),
                Text('R ${estimate.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 20),
            if (t.isBidding) ...[
              const Text('Your offer (drivers will counter)', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextField(
                controller: _offer,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(prefixText: 'R ', prefixStyle: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () => _showBidsSheet(context),
              child: Text(t.isBidding ? 'Send offer to drivers' : 'Confirm ${t.label}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(IconData icon, String label, String hint) => TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: ShapColors.neon),
        ),
      );

  void _showBidsSheet(BuildContext context) {
    // Demo: shows how live driver bids would stream in (via SocketService).
    showModalBottomSheet(
      context: context,
      backgroundColor: ShapColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Drivers bidding', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _bid('Lerato D.', 4.8, 72),
          _bid('Sipho M.', 4.6, 75),
          _bid('Nandi K.', 4.9, 80),
        ]),
      ),
    );
  }

  Widget _bid(String name, double rating, int amount) => ListTile(
        leading: const CircleAvatar(backgroundColor: ShapColors.primary, child: Icon(Icons.person, color: Colors.white)),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), Text(' $rating', style: const TextStyle(color: Colors.white54))]),
        trailing: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ShapColors.success),
          onPressed: () => Navigator.pop(context),
          child: Text('R $amount'),
        ),
      );
}
