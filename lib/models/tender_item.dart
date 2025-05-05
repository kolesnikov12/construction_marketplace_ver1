class TenderItem {
  final String id;
  final String categoryId;
  final String? subcategoryId;
  final String itemName;
  final String? manufacturer;
  final String? model;
  final double quantity;
  final String unit;

  TenderItem({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.itemName,
    this.manufacturer,
    this.model,
    required this.quantity,
    required this.unit,
  });

  factory TenderItem.fromJson(Map<String, dynamic> json) {
    return TenderItem(
      id: json['id'],
      categoryId: json['categoryId'],
      subcategoryId: json['subcategoryId'],
      itemName: json['itemName'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      quantity: (json['quantity'] is int)
          ? (json['quantity'] as int).toDouble()
          : json['quantity'],
      unit: json['unit'],
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
}