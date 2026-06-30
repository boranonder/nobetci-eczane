enum UserRole { user, pharmacy }

class AppUserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? pharmacyAddress;

  const AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.pharmacyAddress,
  });

  bool get isPharmacy => role == UserRole.pharmacy;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role.name,
        if (phone != null) 'phone': phone,
        if (pharmacyAddress != null) 'pharmacyAddress': pharmacyAddress,
      };

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'pharmacy' ? UserRole.pharmacy : UserRole.user,
      phone: json['phone'],
      pharmacyAddress: json['pharmacyAddress'],
    );
  }
}
