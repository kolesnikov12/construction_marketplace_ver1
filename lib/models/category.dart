class Category {
  final String id;
  final String nameEn;
  final String nameFr;
  final String? parentId;
  final List<Category>? subcategories;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    this.parentId,
    this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameEn: json['nameEn'],
      nameFr: json['nameFr'],
      parentId: json['parentId'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
          .map((i) => Category.fromJson(i))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameFr': nameFr,
      'parentId': parentId,
      'subcategories': subcategories?.map((e) => e.toJson()).toList(),
    };
  }
}