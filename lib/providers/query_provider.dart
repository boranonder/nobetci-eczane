import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/drug_model.dart';
import '../models/pharmacy_model.dart';
import '../models/query_model.dart';
import '../services/call_service.dart';
import '../services/firebase_service.dart';
import '../services/openai_service.dart';
import '../services/whatsapp_service.dart';

class QueryProvider extends ChangeNotifier {
  final OpenAIService _openai = OpenAIService();
  final WhatsAppService _whatsapp = WhatsAppService();
  final FirebaseService _firebase = FirebaseService();
  final CallService _callService = CallService();
  final _uuid = const Uuid();

  List<QueryModel> _queries = [];
  bool _isProcessing = false;
  String? _processingStatus;
  List<DrugModel> _extractedDrugs = [];

  final Map<String, StreamSubscription> _listeners = {};

  List<QueryModel> get queries => List.unmodifiable(_queries);
  bool get isProcessing => _isProcessing;
  String? get processingStatus => _processingStatus;
  List<DrugModel> get extractedDrugs => _extractedDrugs;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('queries');
    if (json != null) {
      _queries = QueryModel.listFromJsonString(json);
      notifyListeners();
    }

    try {
      final remote = await _firebase.fetchAll();
      if (remote.isNotEmpty) {
        _queries = remote.map((e) => QueryModel.fromJson(e)).toList();
        notifyListeners();
        _saveLocal();
      }
    } catch (_) {}

    // Bekleyen aramaları dinlemeye devam et
    for (final q in _queries.where((q) => _isActiveStatus(q.status))) {
      _watchQuery(q.id);
    }
  }

  bool _isActiveStatus(QueryStatus s) =>
      s == QueryStatus.sent ||
      s == QueryStatus.calling ||
      s == QueryStatus.transcribing;

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('queries', QueryModel.listToJsonString(_queries));
  }

  Future<List<DrugModel>> extractDrugsFromImage(File image) async {
    _isProcessing = true;
    _processingStatus = 'Görsel analiz ediliyor...';
    _extractedDrugs = [];
    notifyListeners();

    try {
      _extractedDrugs = await _openai.extractDrugsFromImage(image);
      return _extractedDrugs;
    } catch (e) {
      _processingStatus = 'Görsel okunamadı: $e';
      return [];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<QueryModel> sendQuery({
    required List<DrugModel> drugs,
    required PharmacyModel pharmacy,
  }) async {
    final id = _uuid.v4().substring(0, 8).toUpperCase();
    final drugList = drugs.map((d) => d.displayName).toList();
    final drugName = drugList.join(', ');
    final query = QueryModel(
      id: id,
      drugName: drugName,
      drugList: drugList,
      pharmacyId: pharmacy.id,
      pharmacyName: pharmacy.name,
      pharmacyPhone: pharmacy.phone,
      timestamp: DateTime.now(),
      status: QueryStatus.pending,
    );

    _queries.insert(0, query);
    notifyListeners();

    _isProcessing = true;
    _processingStatus = 'Sorgu gönderiliyor...';
    notifyListeners();

    try {
      await _firebase.saveQuery(query.toJson());

      // ─── 1. Önce sesli arama dene ───────────────────────────────
      debugPrint('CallService configured: ${_callService.isConfigured}');
      if (_callService.isConfigured) {
        final phone = await _resolvePhone(pharmacy);
        debugPrint('Resolved phone: $phone');
        if (phone != null) {
          _processingStatus = 'Eczane aranıyor...';
          notifyListeners();

          final called = await _callService.makeCall(
            queryId: id,
            drugList: drugList,
            pharmacyPhone: phone,
            pharmacyName: pharmacy.name,
          );
          debugPrint('makeCall result: $called');

          if (called) {
            query.status = QueryStatus.calling;
            await _firebase.saveQuery(query.toJson());
            _watchQuery(id);
            return query;
          }
        }
      }

      // ─── 2. WhatsApp fallback ────────────────────────────────────
      bool sent = false;
      final token = dotenv.env['WHATSAPP_TOKEN'] ?? '';

      if (token.isNotEmpty && token != 'buraya-ekle') {
        sent = await _whatsapp.sendInteractiveQuery(
          queryId: id,
          drugName: drugName,
          pharmacyName: pharmacy.name,
        );
      }

      if (!sent) {
        final phone = await _resolvePhone(pharmacy);
        final message =
            '💊 *$drugName* mevcut mu?\n\n📍 Eczane: ${pharmacy.name}\n🔑 Sorgu ID: $id\n\nLütfen Evet veya Hayır olarak yanıtlayın.';
        if (phone != null) {
          sent = await _whatsapp.openWhatsAppDeepLink(phone, message);
        }
      }

      query.status = sent ? QueryStatus.sent : QueryStatus.pending;
      await _firebase.saveQuery(query.toJson());
      if (sent) _watchQuery(id);
    } catch (e) {
      query.status = QueryStatus.pending;
    } finally {
      _isProcessing = false;
      _processingStatus = null;
      notifyListeners();
      _saveLocal();
    }

    return query;
  }

  Future<String?> _resolvePhone(PharmacyModel pharmacy) async {
    // 1. Firebase'de kayıtlı eczane numarası (production)
    final registered = await _firebase.getPharmacyPhone(pharmacy.name);
    if (registered != null) return _cleanPhone(registered);

    // 2. Test numarası (geliştirme aşamasında)
    final testPhone = dotenv.env['WHATSAPP_TEST_RECIPIENT'] ?? '';
    if (testPhone.isNotEmpty && testPhone != '905xxxxxxxxx') {
      return _cleanPhone(testPhone);
    }

    // 3. OSM'den gelen numara (son çare)
    return pharmacy.phone != null ? _cleanPhone(pharmacy.phone!) : null;
  }

  String _cleanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '+$digits';
  }

  void _watchQuery(String queryId) {
    if (_listeners.containsKey(queryId)) return;

    _listeners[queryId] = _firebase.watchQuery(queryId).listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final statusStr = data['status'] as String?;
      if (statusStr == null) return;

      final index = _queries.indexWhere((q) => q.id == queryId);
      if (index == -1) return;

      final newStatus = _parseStatus(statusStr);
      _queries[index].status = newStatus;
      _queries[index].isAvailable = data['isAvailable'] as bool?;
      _queries[index].callMessage = data['callMessage'] as String?;
      _queries[index].fullMessage = data['fullMessage'] as String?;
      _queries[index].alternative = data['alternative'] as String?;
      notifyListeners();
      _saveLocal();

      // Terminal durumlarda dinlemeyi durdur
      if (_isTerminalStatus(newStatus)) {
        _listeners[queryId]?.cancel();
        _listeners.remove(queryId);
      }
    });
  }

  QueryStatus _parseStatus(String s) {
    switch (s) {
      case 'calling':
        return QueryStatus.calling;
      case 'transcribing':
        return QueryStatus.transcribing;
      case 'available':
        return QueryStatus.available;
      case 'unavailable':
        return QueryStatus.unavailable;
      case 'no-answer':
        return QueryStatus.noAnswer;
      case 'unclear':
        return QueryStatus.unclear;
      case 'error':
        return QueryStatus.error;
      case 'sent':
        return QueryStatus.sent;
      default:
        return QueryStatus.pending;
    }
  }

  bool _isTerminalStatus(QueryStatus s) =>
      s == QueryStatus.available ||
      s == QueryStatus.unavailable ||
      s == QueryStatus.noAnswer ||
      s == QueryStatus.unclear ||
      s == QueryStatus.error ||
      s == QueryStatus.timeout;

  Future<void> cancelQuery(String queryId) async {
    _listeners[queryId]?.cancel();
    _listeners.remove(queryId);

    final index = _queries.indexWhere((q) => q.id == queryId);
    if (index == -1) return;
    _queries[index].status = QueryStatus.cancelled;
    notifyListeners();

    await _firebase.updateQueryField(queryId, 'status', 'cancelled');
    _saveLocal();
  }

  Future<void> updateQueryStatus(String queryId, bool isAvailable) async {
    final index = _queries.indexWhere((q) => q.id == queryId);
    if (index == -1) return;
    _queries[index].status =
        isAvailable ? QueryStatus.available : QueryStatus.unavailable;
    _queries[index].isAvailable = isAvailable;
    notifyListeners();
    await _firebase.updateStatus(queryId, isAvailable);
    _saveLocal();
  }

  void clearAll() {
    for (final sub in _listeners.values) {
      sub.cancel();
    }
    _listeners.clear();
    _queries.clear();
    notifyListeners();
    _saveLocal();
  }

  @override
  void dispose() {
    for (final sub in _listeners.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
