import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CallService {
  String get _backendUrl => dotenv.env['BACKEND_URL'] ?? '';

  bool get isConfigured =>
      _backendUrl.isNotEmpty && _backendUrl != 'https://abc123.ngrok-free.app';

  Future<bool> makeCall({
    required String queryId,
    required List<String> drugList,
    required String pharmacyPhone,
    required String pharmacyName,
  }) async {
    if (!isConfigured) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/make-call'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'queryId': queryId,
              'drugList': drugList,
              'pharmacyPhone': pharmacyPhone,
              'pharmacyName': pharmacyName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
