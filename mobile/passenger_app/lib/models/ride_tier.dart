import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The three Shap ride categories.
enum RideTier { ola, mojo, grand }

extension RideTierX on RideTier {
  String get api => name.toUpperCase(); // OLA / MOJO / GRAND
  String get label => switch (this) {
        RideTier.ola => 'Shap Ola',
        RideTier.mojo => 'Shap Mojo',
        RideTier.grand => 'Shap Grand',
      };
  String get tagline => switch (this) {
        RideTier.ola => 'Everyday rides with bidding',
        RideTier.mojo => 'Premium comfort, fixed price',
        RideTier.grand => 'Executive luxury',
      };
  IconData get icon => switch (this) {
        RideTier.ola => Icons.directions_car,
        RideTier.mojo => Icons.local_taxi,
        RideTier.grand => Icons.star,
      };
  Color get accent => switch (this) {
        RideTier.ola => ShapColors.neon,
        RideTier.mojo => ShapColors.primary,
        RideTier.grand => const Color(0xFFFFC107),
      };
  bool get isBidding => this == RideTier.ola;
}
