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

  factory Tender.fromJson(Map<String, dynamic> json) {
    return Tender(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      budget: (json['budget'] is int)
          ? (json['budget'] as int).toDouble()
          : json['budget'],
      deliveryOption: json['deliveryOption'] is String
          ? stringToDeliveryOption(json['deliveryOption'])
          : DeliveryOption.values[json['deliveryOption'] ?? 0],
      validUntil: json['validUntil'] is Timestamp
          ? (json['validUntil'] as Timestamp).toDate()
          : DateTime.parse(json['validUntil']),
      status: json['status'] is String
          ? stringToTenderStatus(json['status'])
          : TenderStatus.values[json['status'] ?? 0],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      items: (json['items'] as List?)
          ?.map((i) => TenderItem.fromJson(i))
          ?.toList() ?? [],
      attachmentUrls: (json['attachmentUrls'] as List?)?.cast<String>(),
    );
  }

  factory Tender.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Ensure the ID is in the data
    return Tender.fromJson(data);
  }

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

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    // Convert DateTime objects to Firestore Timestamps
    json['validUntil'] = Timestamp.fromDate(validUntil);
    json['createdAt'] = Timestamp.fromDate(createdAt);
    // Remove ID as it will be the document ID
    return json;
  }
}