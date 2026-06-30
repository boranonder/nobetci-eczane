import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _db = FirebaseService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? pharmacyAddress,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final user = AppUserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      phone: phone,
      pharmacyAddress: pharmacyAddress,
    );

    await _db.saveUserProfile(user);
    return user;
  }

  Future<AppUserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _db.getUserProfile(cred.user!.uid);
  }

  Future<void> signOut() => _auth.signOut();
}
