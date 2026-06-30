import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/pharmacy_model.dart';

class OverpassService {
  static const _mirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  Future<List<PharmacyModel>> fetchNearbyPharmacies(double lat, double lon) async {
    final query =
        '[out:json][timeout:60];(node["amenity"="pharmacy"](around:${ApiConstants.pharmacySearchRadius},$lat,$lon);way["amenity"="pharmacy"](around:${ApiConstants.pharmacySearchRadius},$lat,$lon););out center tags;';

    Object? lastError;

    for (final mirror in _mirrors) {
      try {
        final response = await http.post(
          Uri.parse(mirror),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': '*/*',
          },
          body: 'data=${Uri.encodeComponent(query)}',
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final elements = data['elements'] as List<dynamic>;
          return elements
              .map((e) => PharmacyModel.fromOverpass(e as Map<String, dynamic>))
              .where((p) => p.lat != 0 && p.lon != 0)
              .toList();
        }
        lastError = 'HTTP ${response.statusCode} ($mirror)';
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Tüm sunucular başarısız: $lastError');
  }
}
