class TenderItem {
  final String id;
  final String categoryId;
  final String subcategoryId;
  final String itemName;
  final String manufacturer;
  final String model;
  final double quantity;
  final String unit;

  TenderItem({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.itemName,
    required this.manufacturer,
    required this.model,
    required this.quantity,
    required this.unit,
  });

  factory TenderItem.fromJson(Map<String, dynamic> json) {
    return TenderItem(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subcategoryId: json['subcategoryId'] ?? '',
      itemName: json['itemName'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      quantity: (json['quantity'] is int)
          ? (json['quantity'] as int).toDouble()
          : (json['quantity'] ?? 0.0),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'itemName': itemName,
      'manufacturer': manufacturer,
      'model': model,
      'quantity': quantity,
      'unit': unit,
    };
  }

  TenderItem copyWith({
    String? id,
    String? categoryId,
    String? subcategoryId,
    String? itemName,
    String? manufacturer,
    String? model,
    double? quantity,
    String? unit,
  }) {
    return TenderItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      itemName: itemName ?? this.itemName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}