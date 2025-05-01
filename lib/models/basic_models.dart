
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? fcmToken; // Для push-повідомлень
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences; // Налаштування користувача
  final List<String>? savedAddressIds; // Збережені адреси
  final bool isEmailVerified;

  User( {
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.fcmToken,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.savedAddressIds,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      fcmToken: json['fcmToken'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      preferences: json['preferences'],
      savedAddressIds: json['savedAddressIds'],
      isEmailVerified: json['isEmailVerified']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'savedAddressIds': savedAddressIds,
      'isEmailVerified': isEmailVerified
    };
  }
}

// lib/models/category.dart

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

// lib/models/tender.dart

enum DeliveryOption { pickup, delivery, discuss }
enum TenderStatus { open, closed, extended }

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
      quantity: json['quantity'],
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

class Tender {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String city;
  final double budget;
  final DeliveryOption deliveryOption;
  final DateTime validUntil;
  final TenderStatus status;
  final DateTime createdAt;
  final List<TenderItem> items;
  final List<String>? attachmentUrls;

  Tender({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.city,
    required this.budget,
    required this.deliveryOption,
    required this.validUntil,
    required this.status,
    required this.createdAt,
    required this.items,
    this.attachmentUrls,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    return Tender(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      budget: json['budget'],
      deliveryOption: DeliveryOption.values.byName(json['deliveryOption']),
      validUntil: DateTime.parse(json['validUntil']),
      status: TenderStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List).map((i) => TenderItem.fromJson(i)).toList(),
      attachmentUrls: (json['attachmentUrls'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'city': city,
      'budget': budget,
      'deliveryOption': deliveryOption.name,
      'validUntil': validUntil.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'attachmentUrls': attachmentUrls,
    };
  }
}

// lib/models/listing.dart

enum ListingStatus { available, sold, expired }

class ListingItem {
  final String id;
  final String categoryId;
  final String? subcategoryId;
  final String itemName;
  final String? manufacturer;
  final String? model;
  final double quantity;
  final String unit;
  final double? price;
  final bool isFree;

  ListingItem({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.itemName,
    this.manufacturer,
    this.model,
    required this.quantity,
    required this.unit,
    this.price,
    required this.isFree,
  });

  factory ListingItem.fromJson(Map<String, dynamic> json) {
    return ListingItem(
      id: json['id'],
      categoryId: json['categoryId'],
      subcategoryId: json['subcategoryId'],
      itemName: json['itemName'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      quantity: json['quantity'],
      unit: json['unit'],
      price: json['price'],
      isFree: json['isFree'],
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
      'price': price,
      'isFree': isFree,
    };
  }
}

class Listing {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String city;
  final DeliveryOption deliveryOption;
  final DateTime validUntil;
  final ListingStatus status;
  final DateTime createdAt;
  final List<ListingItem> items;
  final List<String>? photoUrls;

  Listing({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.city,
    required this.deliveryOption,
    required this.validUntil,
    required this.status,
    required this.createdAt,
    required this.items,
    this.photoUrls,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      deliveryOption: DeliveryOption.values.byName(json['deliveryOption']),
      validUntil: DateTime.parse(json['validUntil']),
      status: ListingStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List).map((i) => ListingItem.fromJson(i)).toList(),
      photoUrls: (json['photoUrls'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'city': city,
      'deliveryOption': deliveryOption.name,
      'validUntil': validUntil.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'photoUrls': photoUrls,
    };
  }
}