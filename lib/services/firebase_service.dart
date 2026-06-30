import 'package:firebase_database/firebase_database.dart';
import '../models/app_user_model.dart';

class FirebaseService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference get _queries => _db.ref('queries');
  DatabaseReference get _users => _db.ref('users');
  DatabaseReference get _pharmacies => _db.ref('pharmacies');

  // ── Kullanıcı / Eczane profili ──────────────────────────────

  Future<void> saveUserProfile(AppUserModel user) async {
    final node = user.isPharmacy ? _pharmacies : _users;
    await node.child(user.uid).set(user.toJson());
  }

  Future<AppUserModel?> getUserProfile(String uid) async {
    // Önce eczane tablosuna bak, sonra kullanıcı tablosuna
    final pSnap = await _pharmacies.child(uid).get();
    if (pSnap.exists) {
      return AppUserModel.fromJson(Map<String, dynamic>.from(pSnap.value as Map));
    }
    final uSnap = await _users.child(uid).get();
    if (uSnap.exists) {
      return AppUserModel.fromJson(Map<String, dynamic>.from(uSnap.value as Map));
    }
    return null;
  }

  // Eczane adına göre kayıtlı WhatsApp numarasını bul
  Future<String?> getPharmacyPhone(String pharmacyName) async {
    final snap = await _pharmacies.get();
    if (!snap.exists) return null;

    final map = snap.value as Map<dynamic, dynamic>;
    for (final entry in map.values) {
      final data = Map<String, dynamic>.from(entry as Map);
      final name = (data['name'] as String? ?? '').toLowerCase();
      if (name == pharmacyName.toLowerCase() || name.contains(pharmacyName.toLowerCase())) {
        return data['phone'] as String?;
      }
    }
    return null;
  }

  // ── Sorgular ────────────────────────────────────────────────

  Future<void> saveQuery(Map<String, dynamic> data) async {
    await _queries.child(data['id']).set(data);
  }

  Future<void> updateQueryField(String queryId, String field, dynamic value) async {
    await _queries.child(queryId).update({field: value});
  }

  Future<void> updateStatus(String queryId, bool isAvailable) async {
    await _queries.child(queryId).update({
      'status': isAvailable ? 'available' : 'unavailable',
      'isAvailable': isAvailable,
    });
  }

  Stream<DatabaseEvent> watchQuery(String queryId) {
    return _queries.child(queryId).onValue;
  }

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final snapshot = await _queries.orderByChild('timestamp').get();
    if (!snapshot.exists) return [];

    final map = snapshot.value as Map<dynamic, dynamic>;
    final result = map.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList()
      ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    return result;
  }
}
