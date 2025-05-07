import 'dart:io' as web;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/listing.dart';
import '../models/listing_item.dart';
import '../models/enums.dart';

class ListingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();

  // Fetch listings with filters
  Future<List<Listing>> fetchListings({
    String? searchQuery,
    String? city,
    String? categoryId,
    bool? unviewed,
    List<String>? deliveryOptions,
  }) async {
    try {
      Query query = _firestore.collection('listings');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.where('title', isGreaterThanOrEqualTo: searchQuery)
            .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // Filter by delivery options
      if (deliveryOptions != null && deliveryOptions.isNotEmpty) {
        query = query.where('deliveryOption', whereIn: deliveryOptions);
      }

      // Execute query
      final snapshot = await query.get();
      final listings = snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();

      // Filter by category - has to be done client-side because of Firestore limitations
      if (categoryId != null && categoryId.isNotEmpty) {
        listings.removeWhere((listing) => !listing.items.any((item) =>
        item.categoryId == categoryId || item.subcategoryId == categoryId));
      }

      return listings;
    } catch (e) {
      print('Error fetching listings: $e');
      throw Exception('Failed to fetch listings: $e');
    }
  }

  // Fetch user listings
  Future<List<Listing>> fetchUserListings(String userId) async {
    try {
      final snapshot = await _firestore.collection('listings')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching user listings: $e');
      throw Exception('Failed to fetch user listings: $e');
    }
  }

  // Fetch listing by ID
  Future<Listing> fetchListingById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('listings').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Listing not found');
      }

      return Listing.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error fetching listing: $e');
      throw Exception('Failed to fetch listing: $e');
    }
  }

  // Create listing
  Future<Listing> createListing({
    required String userId,
    required String title,
    required String city,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
    required List<dynamic> photos,
  }) async {
    try {
      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create listing items
      final items = itemsData.map((itemData) => ListingItem(
        id: _uuid.v4(),
        categoryId: itemData['categoryId'],
        subcategoryId: itemData['subcategoryId'],
        itemName: itemData['itemName'],
        manufacturer: itemData['manufacturer'],
        model: itemData['model'],
        quantity: double.parse(itemData['quantity'].toString()),
        unit: itemData['unit'],
        price: itemData['isFree'] ? null : double.parse(itemData['price'].toString()),
        isFree: itemData['isFree'] ?? false,
      )).toList();

      // Upload photos
      List<String> photoUrls = await _uploadPhotos(photos, userId);

      // Create listing object
      final listing = Listing(
        id: _uuid.v4(), // Will be replaced by Firestore document ID
        userId: userId,
        title: title,
        description: description,
        city: city,
        deliveryOption: deliveryOption,
        validUntil: validUntil,
        status: ListingStatus.available,
        createdAt: now,
        items: items,
        photoUrls: photoUrls,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('listings').add(listing.toFirestore());

      // Return listing with the correct Firestore ID
      return listing.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating listing: $e');
      throw Exception('Failed to create listing: $e');
    }
  }

  // Update listing
  Future<void> updateListing({
    required String id,
    required String title,
    required String city,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
    List<String>? photoUrls,
  }) async {
    try {
      // Get the existing listing to preserve createdAt and other fields
      final existingListing = await fetchListingById(id);

      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create listing items
      final items = itemsData.map((itemData) => ListingItem(
        id: itemData['id'] ?? _uuid.v4(),
        categoryId: itemData['categoryId'],
        subcategoryId: itemData['subcategoryId'],
        itemName: itemData['itemName'],
        manufacturer: itemData['manufacturer'],
        model: itemData['model'],
        quantity: double.parse(itemData['quantity'].toString()),
        unit: itemData['unit'],
        price: itemData['isFree'] ? null : double.parse(itemData['price'].toString()),
        isFree: itemData['isFree'] ?? false,
      )).toList();

      // Update listing object
      final listing = Listing(
        id: id,
        userId: existingListing.userId,
        title: title,
        description: description,
        city: city,
        deliveryOption: deliveryOption,
        validUntil: validUntil,
        status: existingListing.status,
        createdAt: existingListing.createdAt,
        items: items,
        photoUrls: photoUrls ?? existingListing.photoUrls,
      );

      // Update in Firestore
      await _firestore.collection('listings').doc(id).update(listing.toFirestore());
    } catch (e) {
      print('Error updating listing: $e');
      throw Exception('Failed to update listing: $e');
    }
  }

  // Delete listing
  Future<void> deleteListing(String id) async {
    try {
      // Get the listing first to delete associated photos
      final listing = await fetchListingById(id);

      // Delete photos from Storage
      if (listing.photoUrls != null && listing.photoUrls!.isNotEmpty) {
        await _deletePhotos(listing.photoUrls!);
      }

      // Delete the listing document
      await _firestore.collection('listings').doc(id).delete();
    } catch (e) {
      print('Error deleting listing: $e');
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Toggle favorite listing
  Future<bool> toggleFavoriteListing(String listingId, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> favoriteListings = List<String>.from(userData['favoriteListings'] ?? []);

      bool isFavorite = favoriteListings.contains(listingId);

      if (isFavorite) {
        favoriteListings.remove(listingId);
      } else {
        favoriteListings.add(listingId);
      }

      await _firestore.collection('users').doc(userId).update({
        'favoriteListings': favoriteListings,
      });

      return !isFavorite; // Return the new state
    } catch (e) {
      print('Error toggling favorite listing: $e');
      throw Exception('Failed to toggle favorite listing: $e');
    }
  }

  // Fetch favorite listings
  Future<List<Listing>> fetchFavoriteListings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> favoriteListings = List<String>.from(userData['favoriteListings'] ?? []);

      if (favoriteListings.isEmpty) {
        return [];
      }

      // Firestore has a limit on the number of items in an 'in' query
      const batchSize = 10;
      List<Listing> results = [];

      for (int i = 0; i < favoriteListings.length; i += batchSize) {
        final end = (i + batchSize < favoriteListings.length)
            ? i + batchSize
            : favoriteListings.length;
        final batch = favoriteListings.sublist(i, end);

        final snapshot = await _firestore.collection('listings')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        results.addAll(snapshot.docs.map((doc) => Listing.fromFirestore(doc)));
      }

      return results;
    } catch (e) {
      print('Error fetching favorite listings: $e');
      throw Exception('Failed to fetch favorite listings: $e');
    }
  }

  // Mark listing as sold
  Future<void> markListingAsSold(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': listingStatusToString(ListingStatus.sold),
      });
    } catch (e) {
      print('Error marking listing as sold: $e');
      throw Exception('Failed to mark listing as sold: $e');
    }
  }

  // Helper methods
  Future<List<String>> _uploadPhotos(List<dynamic> photos, String userId) async {
    List<String> urls = [];

    for (var photo in photos) {
      final String fileName = '${_uuid.v4()}_${photo.path.split('/').last}';
      final ref = _storage.ref().child('listings/$userId/$fileName');

      // Handle both normal File and web.File
      if (photo is web.File) {
        final arrayBuffer = await photo.arrayBuffer().toDart;
        final uint8List = arrayBuffer.toDart.asUint8List();

        final uploadTask = ref.putData(uint8List);
        await uploadTask.whenComplete(() => null);
      } else {
        final uploadTask = ref.putFile(photo);
        await uploadTask.whenComplete(() => null);
      }

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> _deletePhotos(List<String> urls) async {
    for (var url in urls) {
      try {
        // Get the storage reference from the URL
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Error deleting photo: $e');
        // Continue with the next photo
      }
    }
  }
}