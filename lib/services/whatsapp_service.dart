import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/api_constants.dart';

class WhatsAppService {
  final Dio _dio = Dio();

  // Yöntem 1: Deep link — kurulum gerektirmez, WhatsApp açılır
  Future<bool> openWhatsAppDeepLink(String phoneNumber, String message) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final number = cleaned.startsWith('0') ? '9$cleaned'.substring(1) : cleaned;
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('whatsapp://send?phone=$number&text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  // Yöntem 2: WhatsApp Business Cloud API — interaktif butonlu mesaj
  // Eczane (kendi telefonun) Evet/Hayır butonuna basınca webhook alır
  Future<bool> sendInteractiveQuery({
    required String queryId,
    required String drugName,
    required String pharmacyName,
    String? recipientOverride, // Test: kendi numaran
  }) async {
    final token = dotenv.env['WHATSAPP_TOKEN'] ?? '';
    final phoneNumberId = dotenv.env['WHATSAPP_PHONE_NUMBER_ID'] ?? '';
    final recipient = recipientOverride ?? dotenv.env['WHATSAPP_TEST_RECIPIENT'] ?? '';

    if (token.isEmpty || token == 'buraya-ekle') return false;

    final body = {
      'messaging_product': 'whatsapp',
      'to': recipient,
      'type': 'interactive',
      'interactive': {
        'type': 'button',
        'body': {
          'text': '💊 *$drugName* mevcut mu?\n\n📍 Eczane: $pharmacyName\n🔑 Sorgu: $queryId'
        },
        'action': {
          'buttons': [
            {
              'type': 'reply',
              'reply': {'id': 'YES_$queryId', 'title': 'Evet ✓'}
            },
            {
              'type': 'reply',
              'reply': {'id': 'NO_$queryId', 'title': 'Hayır ✗'}
            }
          ]
        }
      }
    };

    final response = await _dio.post(
      '${ApiConstants.whatsappBaseUrl}/$phoneNumberId/messages',
      data: jsonEncode(body),
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );

    return response.statusCode == 200;
  }
}
