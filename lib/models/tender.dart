import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'tender_item.dart';

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

  // Метод для копіювання об'єкта з можливістю зміни окремих полів
  Tender copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? city,
    double? budget,
    DeliveryOption? deliveryOption,
    DateTime? validUntil,
    TenderStatus? status,
    DateTime? createdAt,
    List<TenderItem>? items,
    List<String>? attachmentUrls,
  }) {
    return Tender(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      budget: budget ?? this.budget,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  // Фабричний метод для створення об'єкта з JSON
  factory Tender.fromJson(Map<String, dynamic> json) {
    return Tender(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      city: json['city'] ?? '',
      budget: (json['budget'] is int)
          ? (json['budget'] as int).toDouble()
          : (json['budget'] ?? 0.0),
      deliveryOption: json['deliveryOption'] is String
          ? stringToDeliveryOption(json['deliveryOption'])
          : DeliveryOption.values[json['deliveryOption'] ?? 0],
      validUntil: json['validUntil'] is Timestamp
          ? (json['validUntil'] as Timestamp).toDate()
          : (json['validUntil'] is String
          ? DateTime.parse(json['validUntil'])
          : DateTime.now()),
      status: json['status'] is String
          ? stringToTenderStatus(json['status'])
          : TenderStatus.values[json['status'] ?? 0],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now()),
      items: (json['items'] as List?)
          ?.map((i) => TenderItem.fromJson(i))
          .toList() ?? [],
      attachmentUrls: (json['attachmentUrls'] as List?)?.cast<String>(),
    );
  }

  // Фабричний метод для створення об'єкта з документа Firestore
  factory Tender.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Додаємо ID документа до даних
    data['id'] = doc.id;
    return Tender.fromJson(data);
  }

  // Метод для перетворення об'єкта у JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'city': city,
      'budget': budget,
      'deliveryOption': deliveryOptionToString(deliveryOption),
      'validUntil': validUntil.toIso8601String(),
      'status': tenderStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'attachmentUrls': attachmentUrls,
    };
  }

  // Метод для перетворення об'єкта у формат для Firestore
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    // Перетворюємо DateTime в Timestamp для Firestore
    json['validUntil'] = Timestamp.fromDate(validUntil);
    json['createdAt'] = Timestamp.fromDate(createdAt);
    return json;
  }
}