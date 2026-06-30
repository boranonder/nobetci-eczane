import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService();

  Position? _position;
  bool _isLoading = false;
  String? _error;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _position != null;

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _position = await _service.getCurrentPosition();
      if (_position == null) _error = 'Konum alınamadı. Lütfen izin ver.';
    } catch (e) {
      _error = 'Konum hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
