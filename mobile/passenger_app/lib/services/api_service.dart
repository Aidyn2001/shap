import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin REST client for the Shap API.
/// On Android emulator use 10.0.2.2 to reach the host machine.
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'SHAP_API',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  String? _token;
  String? get token => _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> _saveToken(String t) async {
    _token = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _post(String path, Map body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(data['error'] ?? 'Request failed');
    return data;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(data['error'] ?? 'Request failed');
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post('/auth/login', {'email': email, 'password': password});
    await _saveToken(data['token']);
    return data['user'];
  }

  Future<Map<String, dynamic>> register(Map body) async {
    final data = await _post('/auth/register', body);
    await _saveToken(data['token']);
    return data['user'];
  }

  Future<double> quote({required String tier, required double distanceKm, required double durationMin}) async {
    final data = await _post('/rides/quote', {
      'tier': tier, 'distanceKm': distanceKm, 'durationMin': durationMin,
    });
    return (data['estimatedFare'] as num).toDouble();
  }

  Future<Map<String, dynamic>> createRide(Map body) async =>
      (await _post('/rides', body))['ride'];

  Future<List> myRides() async => (await _get('/rides/mine'))['rides'] as List;

  Future<List> bids(String rideId) async =>
      (await _get('/rides/$rideId/bids'))['bids'] as List;

  Future<Map<String, dynamic>> acceptBid(String bidId) async =>
      (await _post('/bids/$bidId/accept', {}))['ride'];
}
