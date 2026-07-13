class Ride {
  final String id;
  final String tier;
  final String status;
  final double estimatedFare;
  final double? finalFare;
  final String pickupAddr;
  final String dropAddr;

  Ride({
    required this.id,
    required this.tier,
    required this.status,
    required this.estimatedFare,
    required this.pickupAddr,
    required this.dropAddr,
    this.finalFare,
  });

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: j['id'],
        tier: j['tier'],
        status: j['status'],
        estimatedFare: (j['estimatedFare'] as num).toDouble(),
        finalFare: (j['finalFare'] as num?)?.toDouble(),
        pickupAddr: j['pickupAddr'] ?? '',
        dropAddr: j['dropAddr'] ?? '',
      );
}
