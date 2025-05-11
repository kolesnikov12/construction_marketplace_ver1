import 'dart:async';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/tender.dart';
import '../models/tender_item.dart';
import '../models/enums.dart';

class TenderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();

  // Fetch tenders with filters
  Future<List<Tender>> fetchTenders({
    String? searchQuery,
    String? city,
    String? categoryId,
    bool? userBids,
    bool? unviewed,
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection('tenders');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Firestore doesn't support full-text search natively
        // For simple cases, we can use field matching
        query = query.where('title', isGreaterThanOrEqualTo: searchQuery)
            .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        // For items in arrays, we need a different approach
        // This is a limitation of Firestore - can't filter on nested array fields efficiently
        // In a real app, you might want to denormalize data or use a different approach
      }

      if (userBids == true && userId != null) {
        // Assuming we have a 'bidders' array in the tender document
        query = query.where('bidders', arrayContains: userId);
      }

      // Execute query
      final snapshot = await query.get();
      final tenders = snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();

      // For category filtering which couldn't be done at the database level
      if (categoryId != null && categoryId.isNotEmpty) {
        tenders.removeWhere((tender) => !tender.items.any((item) =>
        item.categoryId == categoryId || item.subcategoryId == categoryId));
      }

      return tenders;
    } catch (e) {
      print('Error fetching tenders: $e');
      throw Exception('Failed to fetch tenders: $e');
    }
  }

  // Fetch user tenders
  Future<List<Tender>> fetchUserTenders(String userId) async {
    try {
      final snapshot = await _firestore.collection('tenders')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching user tenders: $e');
      throw Exception('Failed to fetch user tenders: $e');
    }
  }

  // Fetch tender by ID
  Future<Tender> fetchTenderById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('tenders').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Tender not found');
      }

      return Tender.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error fetching tender: $e');
      throw Exception('Failed to fetch tender: $e');
    }
  }

  // Create tender
  Future<Tender> createTender({
    required String userId,
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
    List<dynamic>? attachments,
  }) async {
    try {
      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create tender items
      final items = itemsData.map((itemData) => TenderItem(
        id: '',
        categoryId: itemData['categoryId'],
        subcategoryId: itemData['subcategoryId'],
        itemName: itemData['itemName'],
        manufacturer: itemData['manufacturer'],
        model: itemData['model'],
        quantity: double.parse(itemData['quantity'].toString()),
        unit: itemData['unit'],
      )).toList();

      // Upload attachments if provided
      List<String>? attachmentUrls;
      if (attachments != null && attachments.isNotEmpty) {
        attachmentUrls = await _uploadAttachments(attachments, userId);
      }

      // Create tender object
      final tender = Tender(
        id: '',
        userId: userId,
        title: title,
        description: description,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validUntil: validUntil,
        status: TenderStatus.open,
        createdAt: now,
        items: items,
        attachmentUrls: attachmentUrls,
      );
      print('Firestore payload: ${tender.toFirestore()}');

      // Save to Firestore
      final docRef = await _firestore.collection('tenders').add(tender.toFirestore());

      // Return tender with the correct Firestore ID
      return tender.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating tender: $e');
      throw Exception('Failed to create tender: $e');
    }
  }

  // Update tender
  Future<void> updateTender({
    required String id,
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      // Get the existing tender to preserve createdAt and other fields
      final existingTender = await fetchTenderById(id);

      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create tender items
      final items = itemsData.map((itemData) => TenderItem(
        id: itemData['id'] ?? _uuid.v4(),
        categoryId: itemData['categoryId'],
        subcategoryId: itemData['subcategoryId'],
        itemName: itemData['itemName'],
        manufacturer: itemData['manufacturer'],
        model: itemData['model'],
        quantity: double.parse(itemData['quantity'].toString()),
        unit: itemData['unit'],
      )).toList();

      // Update tender object
      final tender = Tender(
        id: id,
        userId: existingTender.userId,
        title: title,
        description: description,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validUntil: validUntil,
        status: existingTender.status,
        createdAt: existingTender.createdAt,
        items: items,
        attachmentUrls: existingTender.attachmentUrls,
      );

      // Update in Firestore
      await _firestore.collection('tenders').doc(id).update(tender.toFirestore());
    } catch (e) {
      print('Error updating tender: $e');
      throw Exception('Failed to update tender: $e');
    }
  }

  // Delete tender
  Future<void> deleteTender(String id) async {
    try {
      // Get the tender first to delete associated attachments
      final tender = await fetchTenderById(id);

      // Delete attachments from Storage
      if (tender.attachmentUrls != null && tender.attachmentUrls!.isNotEmpty) {
        await _deleteAttachments(tender.attachmentUrls!);
      }

      // Delete the tender document
      await _firestore.collection('tenders').doc(id).delete();
    } catch (e) {
      print('Error deleting tender: $e');
      throw Exception('Failed to delete tender: $e');
    }
  }

  // Toggle favorite tender
  Future<bool> toggleFavoriteTender(String tenderId, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> favoriteTenders = List<String>.from(userData['favoriteTenders'] ?? []);

      bool isFavorite = favoriteTenders.contains(tenderId);

      if (isFavorite) {
        favoriteTenders.remove(tenderId);
      } else {
        favoriteTenders.add(tenderId);
      }

      await _firestore.collection('users').doc(userId).update({
        'favoriteTenders': favoriteTenders,
      });

      return !isFavorite; // Return the new state
    } catch (e) {
      print('Error toggling favorite tender: $e');
      throw Exception('Failed to toggle favorite tender: $e');
    }
  }

  // Fetch favorite tenders
  Future<List<Tender>> fetchFavoriteTenders(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> favoriteTenders = List<String>.from(userData['favoriteTenders'] ?? []);

      if (favoriteTenders.isEmpty) {
        return [];
      }

      // Firestore has a limit on the number of items in an 'in' query
      // So we need to batch the requests if there are many favorites
      const batchSize = 10;
      List<Tender> results = [];

      for (int i = 0; i < favoriteTenders.length; i += batchSize) {
        final end = (i + batchSize < favoriteTenders.length)
            ? i + batchSize
            : favoriteTenders.length;
        final batch = favoriteTenders.sublist(i, end);

        final snapshot = await _firestore.collection('tenders')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        results.addAll(snapshot.docs.map((doc) => Tender.fromFirestore(doc)));
      }

      return results;
    } catch (e) {
      print('Error fetching favorite tenders: $e');
      throw Exception('Failed to fetch favorite tenders: $e');
    }
  }

  // Extend tender
  Future<void> extendTender(String tenderId, int additionalWeeks) async {
    try {
      final tender = await fetchTenderById(tenderId);

      final newValidUntil = tender.validUntil.add(Duration(days: additionalWeeks * 7));

      await _firestore.collection('tenders').doc(tenderId).update({
        'validUntil': Timestamp.fromDate(newValidUntil),
        'status': tenderStatusToString(TenderStatus.extended),
      });
    } catch (e) {
      print('Error extending tender: $e');
      throw Exception('Failed to extend tender: $e');
    }
  }

  // Close tender
  Future<void> closeTender(String tenderId) async {
    try {
      await _firestore.collection('tenders').doc(tenderId).update({
        'status': tenderStatusToString(TenderStatus.closed),
      });
    } catch (e) {
      print('Error closing tender: $e');
      throw Exception('Failed to close tender: $e');
    }
  }

  // Helper methods
  // In your _uploadAttachments method in tender_repository.dart
// In _uploadAttachments method in tender_repository.dart
  // In _uploadAttachments method in tender_repository.dart
  Future<List<String>> _uploadAttachments(List<dynamic> attachments, String userId) async {
    List<String> urls = [];

    for (var attachment in attachments) {
      try {
        String fileName;
        final ref = _storage.ref().child('tenders/$userId/');

        if (kIsWeb) {
          // Для веб використовуємо bytes замість path
          // Якщо attachment це результат FilePicker, беремо ім'я файлу з нього
          if (attachment is PlatformFile) {
            fileName = '${_uuid.v4()}_${attachment.name}';
            final fileRef = ref.child(fileName);
            final task = fileRef.putData(attachment.bytes!);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            urls.add(url);
          } else if (attachment is Uint8List) {
            // Якщо це просто байти
            fileName = '${_uuid.v4()}_file';
            final fileRef = ref.child(fileName);
            final task = fileRef.putData(attachment);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            urls.add(url);
          } else {
            print('Unsupported file type for web platform');
            continue;
          }
        } else {
          // Mobile upload
          if (attachment is io.File) {
            fileName = '${_uuid.v4()}_${attachment.path.split('/').last}';
            final fileRef = ref.child(fileName);
            final task = fileRef.putFile(attachment);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            urls.add(url);
          } else {
            print('Unsupported file type for mobile platform');
            continue;
          }
        }
      } catch (e) {
        print('Error uploading attachment: $e');
        // Continue with next attachment
      }
    }

    return urls;
  }


  Future<void> _deleteAttachments(List<String> urls) async {
    for (var url in urls) {
      try {
        // Get the storage reference from the URL
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Error deleting attachment: $e');
        // Continue with the next attachment
      }
    }
  }
}