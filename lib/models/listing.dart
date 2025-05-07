import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'listing_item.dart';

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

  // Add this method to your Listing class in lib/models/listing.dart
  Listing copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? city,
    DeliveryOption? deliveryOption,
    DateTime? validUntil,
    ListingStatus? status,
    DateTime? createdAt,
    List<ListingItem>? items,
    List<String>? photoUrls,
  }) {
    return Listing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      deliveryOption: json['deliveryOption'] is String
          ? stringToDeliveryOption(json['deliveryOption'])
          : DeliveryOption.values[json['deliveryOption'] ?? 0],
      validUntil: json['validUntil'] is Timestamp
          ? (json['validUntil'] as Timestamp).toDate()
          : DateTime.parse(json['validUntil']),
      status: json['status'] is String
          ? stringToListingStatus(json['status'])
          : ListingStatus.values[json['status'] ?? 0],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      items: (json['items'] as List?)
          ?.map((i) => ListingItem.fromJson(i))
          ?.toList() ?? [],
      photoUrls: (json['photoUrls'] as List?)?.cast<String>(),
    );
  }

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Ensure the ID is in the data
    return Listing.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'city': city,
      'deliveryOption': deliveryOptionToString(deliveryOption),
      'validUntil': validUntil.toIso8601String(),
      'status': listingStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'photoUrls': photoUrls,
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
