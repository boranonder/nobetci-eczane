class PharmacyModel {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? phone;
  final String? address;
  final String? openingHours;
  final bool isDuty;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.phone,
    this.address,
    this.openingHours,
    this.isDuty = false,
  });

  bool get isOpen {
    if (isDuty) return true;
    final hour = DateTime.now().hour;
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.saturday) return hour >= 9 && hour < 14;
    if (weekday == DateTime.sunday) return false;
    return hour >= 9 && hour < 19;
  }

  String get statusLabel {
    if (isDuty) return 'Nöbetçi';
    if (isOpen) return 'Açık';
    return 'Kapalı';
  }

  // WhatsApp deep link (ülke kodu dahil numara, +90 formatında)
  String? get whatsappDeepLink {
    if (phone == null) return null;
    final cleaned = phone!.replaceAll(RegExp(r'[^\d]'), '');
    final number = cleaned.startsWith('0') ? '9${cleaned.substring(1)}' : cleaned;
    return 'whatsapp://send?phone=$number';
  }

  factory PharmacyModel.fromOverpass(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final lat = (element['lat'] ?? element['center']?['lat'] ?? 0.0).toDouble();
    final lon = (element['lon'] ?? element['center']?['lon'] ?? 0.0).toDouble();

    return PharmacyModel(
      id: element['id'].toString(),
      name: tags['name'] ?? tags['brand'] ?? 'Eczane',
      lat: lat,
      lon: lon,
      phone: tags['phone'] ?? tags['contact:phone'],
      address: _buildAddress(tags),
      openingHours: tags['opening_hours'],
    );
  }

  factory PharmacyModel.fromNosyapi(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>? ?? {};
    return PharmacyModel(
      id: 'duty_${data['pharmacyName']}',
      name: data['pharmacyName'] ?? 'Nöbetçi Eczane',
      lat: (location['lat'] ?? 0.0).toDouble(),
      lon: (location['lng'] ?? 0.0).toDouble(),
      phone: data['phone'],
      address: data['address'],
      isDuty: true,
    );
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:street'],
      tags['addr:housenumber'],
      tags['addr:district'],
      tags['addr:city'],
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
