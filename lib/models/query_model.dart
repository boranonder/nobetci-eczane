import 'dart:convert';

enum QueryStatus {
  pending,
  calling,
  transcribing,
  sent,
  available,
  unavailable,
  noAnswer,
  unclear,
  timeout,
  error,
  cancelled,
}

class QueryModel {
  final String id;
  final String drugName;        // display için birleşik isim
  final List<String> drugList;  // tüm ilaçlar (mg dahil)
  final String pharmacyId;
  final String pharmacyName;
  final String? pharmacyPhone;
  final DateTime timestamp;
  QueryStatus status;
  bool? isAvailable;
  String? callMessage;   // kısa özet
  String? fullMessage;   // detaylı GPT yanıtı
  String? alternative;

  QueryModel({
    required this.id,
    required this.drugName,
    List<String>? drugList,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyPhone,
    required this.timestamp,
    this.status = QueryStatus.pending,
    this.isAvailable,
    this.callMessage,
    this.fullMessage,
    this.alternative,
  }) : drugList = drugList ?? [drugName];

  String get statusLabel {
    switch (status) {
      case QueryStatus.pending:
        return 'Hazırlanıyor';
      case QueryStatus.calling:
        return 'Aranıyor';
      case QueryStatus.transcribing:
        return 'Analiz Ediliyor';
      case QueryStatus.sent:
        return 'Bekleniyor';
      case QueryStatus.available:
        return 'Mevcut';
      case QueryStatus.unavailable:
        return 'Mevcut Değil';
      case QueryStatus.noAnswer:
        return 'Açmadı';
      case QueryStatus.unclear:
        return 'Belirsiz';
      case QueryStatus.timeout:
        return 'Yanıt Yok';
      case QueryStatus.error:
        return 'Hata';
      case QueryStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'drugName': drugName,
        'drugList': drugList,
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
        'pharmacyPhone': pharmacyPhone,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'isAvailable': isAvailable,
        'callMessage': callMessage,
        'fullMessage': fullMessage,
        'alternative': alternative,
      };

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['drugList'];
    final List<String> drugList = rawList is List
        ? rawList.map((e) => e.toString()).toList()
        : [json['drugName'] as String? ?? ''];
    return QueryModel(
      id: json['id'],
      drugName: json['drugName'],
      drugList: drugList,
      pharmacyId: json['pharmacyId'],
      pharmacyName: json['pharmacyName'],
      pharmacyPhone: json['pharmacyPhone'],
      timestamp: DateTime.parse(json['timestamp']),
      status: QueryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueryStatus.pending,
      ),
      isAvailable: json['isAvailable'] as bool?,
      callMessage: json['callMessage'] as String?,
      fullMessage: json['fullMessage'] as String?,
      alternative: json['alternative'] as String?,
    );
  }

  static List<QueryModel> listFromJsonString(String s) {
    final list = jsonDecode(s) as List;
    return list.map((e) => QueryModel.fromJson(e)).toList();
  }

  static String listToJsonString(List<QueryModel> queries) {
    return jsonEncode(queries.map((q) => q.toJson()).toList());
  }
}
