import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AppUserModel? _profile;
  bool _isLoading = false;
  String? _error;

  AppUserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  bool get isPharmacy => _profile?.isPharmacy ?? false;

  Stream<User?> get authStateChanges => _service.authStateChanges;

  Future<void> loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _profile = await FirebaseService().getUserProfile(uid);
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? pharmacyAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        pharmacyAddress: pharmacyAddress,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _profile = null;
    notifyListeners();
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanılıyor.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
