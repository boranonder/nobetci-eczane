import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants/api_constants.dart';
import '../models/drug_model.dart';

class OpenAIService {
  final Dio _dio = Dio();

  Future<List<DrugModel>> extractDrugsFromImage(File image) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await _dio.post(
      ApiConstants.openaiUrl,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'model': ApiConstants.openaiModel,
        'max_tokens': 500,
        'messages': [
          {
            'role': 'system',
            'content':
                'Sen bir eczacı asistanısın. Kullanıcı sana ilaç fotoğrafı, reçete veya el yazısı reçete gönderecek. '
                    'Görseldeki ilaç isimlerini çıkar ve SADECE JSON döndür, başka hiçbir şey yazma. '
                    'Format: {"drugs": [{"name": "İlaç Adı", "dosage": "50mg", "quantity": "30 tablet"}]}'
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              },
              {'type': 'text', 'text': 'Bu görseldeki ilaç isimlerini JSON formatında ver.'}
            ]
          }
        ],
      }),
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final drugs = parsed['drugs'] as List<dynamic>;
    return drugs.map((d) => DrugModel.fromJson(d as Map<String, dynamic>)).toList();
  }
}
