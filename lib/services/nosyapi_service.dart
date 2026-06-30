import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants/api_constants.dart';
import '../models/pharmacy_model.dart';

class NosyapiService {
  final Dio _dio = Dio();

  Future<List<PharmacyModel>> fetchDutyPharmacies(String city) async {
    final apiKey = dotenv.env['NOSYAPI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'buraya-ekle') return [];

    final response = await _dio.get(
      ApiConstants.nosyapiUrl,
      queryParameters: {'apiKey': apiKey, 'city': city},
    );

    if (response.data['success'] != true) return [];

    final result = response.data['result'] as List<dynamic>;
    return result
        .map((e) => PharmacyModel.fromNosyapi(e as Map<String, dynamic>))
        .where((p) => p.lat != 0 && p.lon != 0)
        .toList();
  }
}
