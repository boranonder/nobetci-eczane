import 'package:flutter/material.dart';
import '../models/pharmacy_model.dart';
import '../services/overpass_service.dart';
import '../services/nosyapi_service.dart';

class PharmacyProvider extends ChangeNotifier {
  final OverpassService _overpass = OverpassService();
  final NosyapiService _nosyapi = NosyapiService();

  List<PharmacyModel> _allPharmacies = [];
  bool _isLoading = false;
  String? _error;
  PharmacyModel? _selected;

  List<PharmacyModel> get allPharmacies => _allPharmacies;
  List<PharmacyModel> get dutyPharmacies => _allPharmacies.where((p) => p.isDuty).toList();
  List<PharmacyModel> get openPharmacies => _allPharmacies.where((p) => p.isOpen && !p.isDuty).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  PharmacyModel? get selected => _selected;

  void select(PharmacyModel pharmacy) {
    _selected = pharmacy;
    notifyListeners();
  }

  void clearSelection() {
    _selected = null;
    notifyListeners();
  }

  Future<void> fetchPharmacies(double lat, double lon, {String city = 'İstanbul'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Her servis bağımsız — biri hata verse diğeri çalışmaya devam eder
    List<PharmacyModel> overpassList = [];
    List<PharmacyModel> dutyList = [];

    try {
      overpassList = await _overpass.fetchNearbyPharmacies(lat, lon);
    } catch (e) {
      _error = 'Harita verisi alınamadı: $e';
    }

    try {
      dutyList = await _nosyapi.fetchDutyPharmacies(city);
    } catch (_) {
      // Nosyapi hatası sessizce geçilir, Overpass sonuçları gösterilir
    }

    final dutyNames = dutyList.map((d) => d.name.toLowerCase()).toSet();
    final filtered = overpassList.where((p) => !dutyNames.contains(p.name.toLowerCase())).toList();
    _allPharmacies = [...dutyList, ...filtered];

    _isLoading = false;
    notifyListeners();
  }
}
