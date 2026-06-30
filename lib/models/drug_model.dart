class DrugModel {
  final String name;
  final String? dosage;
  final String? quantity;
  final String? activeIngredient;

  const DrugModel({
    required this.name,
    this.dosage,
    this.quantity,
    this.activeIngredient,
  });

  String get displayName {
    if (dosage != null) return '$name $dosage';
    return name;
  }

  factory DrugModel.fromJson(Map<String, dynamic> json) {
    return DrugModel(
      name: json['name'] ?? '',
      dosage: json['dosage'],
      quantity: json['quantity'],
      activeIngredient: json['active_ingredient'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (dosage != null) 'dosage': dosage,
        if (quantity != null) 'quantity': quantity,
        if (activeIngredient != null) 'active_ingredient': activeIngredient,
      };
}
