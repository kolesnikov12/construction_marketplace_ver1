import 'dart:async';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
    TenderStatus? status, // Added status filter
  }) async {
    try {
      Query query = _firestore.collection('tenders');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Firestore doesn't support full-text search natively
        // For simple cases, we can use field matching
        query = query
            .where('title', isGreaterThanOrEqualTo: searchQuery)
            .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: tenderStatusToString(status));
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
      final tenders =
          snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();

      // For category filtering which couldn't be done at the database level
      if (categoryId != null && categoryId.isNotEmpty) {
        tenders.removeWhere((tender) => !tender.items.any((item) =>
            item.categoryId == categoryId || item.subcategoryId == categoryId));
      }

      // Apply unviewed filter if needed
      if (unviewed == true && userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final List<String> viewedTenders =
              List<String>.from(userData['viewedTenders'] ?? []);
          tenders.removeWhere((tender) => viewedTenders.contains(tender.id));
        }
      }

      return tenders;
    } catch (e) {
      print('Error fetching tenders: $e');
      throw Exception('Failed to fetch tenders: $e');
    }
  }

  // Fetch user tenders with status filter
  Future<List<Tender>> fetchUserTenders(String userId,
      {TenderStatus? status}) async {
    try {
      Query query =
          _firestore.collection('tenders').where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: tenderStatusToString(status));
      }

      final snapshot = await query.get();

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

      final tender = Tender.fromFirestore(docSnapshot);
      print('Fetched imageUrls: ${tender.attachmentUrls}');
      return tender;
    } catch (e) {
      print('Error fetching tender: $e');
      throw Exception('Failed to fetch tender: $e');
    }
  }

  // Create tender with images
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
    List<dynamic>? images, // Additional parameter for images
    TenderStatus status = TenderStatus.open, // Default status
  }) async {
    try {
      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create tender items
      final items = itemsData
          .map((itemData) => TenderItem(
                id: '',
                categoryId: itemData['categoryId'],
                subcategoryId: itemData['subcategoryId'],
                itemName: itemData['itemName'],
                manufacturer: itemData['manufacturer'],
                model: itemData['model'],
                quantity: double.parse(itemData['quantity'].toString()),
                unit: itemData['unit'],
              ))
          .toList();

      // Upload attachments if provided
      List<String>? attachmentUrls;
      if (attachments != null && attachments.isNotEmpty) {
        attachmentUrls = await _uploadAttachments(attachments, userId);
        print('Uploaded attachment URLs: $attachmentUrls');
        if (attachmentUrls.isEmpty) {
          print('Warning: No valid attachment URLs generated');
        }
      } else {
        print('No attachments provided for upload');
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
        status: status,
        createdAt: now,
        items: items,
        attachmentUrls: attachmentUrls ?? [],
      );
      print('Firestore payload: ${tender.toFirestore()}');

      // Save to Firestore
      final docRef =
          await _firestore.collection('tenders').add(tender.toFirestore());

      // Return tender with the correct Firestore ID
      return tender.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating tender: $e');
      throw Exception('Failed to create tender: $e');
    }
  }

  // Save tender as draft
  Future<Tender> saveTenderDraft({
    required String userId,
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
    List<dynamic>? attachments,
    List<dynamic>? images,
  }) async {
    return createTender(
        userId: userId,
        title: title,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validWeeks: validWeeks,
        description: description,
        itemsData: itemsData,
        attachments: attachments,
        images: images,
        status: TenderStatus.open);
  }

  // Publish draft tender
  Future<void> publishDraftTender(String tenderId) async {
    try {
      await _firestore.collection('tenders').doc(tenderId).update({
        'status': tenderStatusToString(TenderStatus.open),
      });
    } catch (e) {
      print('Error publishing draft tender: $e');
      throw Exception('Failed to publish draft tender: $e');
    }
  }

  // Update tender with images
  Future<void> updateTender({
    required String id,
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<Map<String, dynamic>> itemsData,
    List<dynamic>? newImages, // New images to add
    List<String>? imagesToDelete, // URLs of images to delete
    TenderStatus? newStatus, // Optional new status
  }) async {
    try {
      // Get the existing tender to preserve createdAt and other fields
      final existingTender = await fetchTenderById(id);

      final now = DateTime.now();
      final validUntil = now.add(Duration(days: validWeeks * 7));

      // Create tender items
      final items = itemsData
          .map((itemData) => TenderItem(
                id: itemData['id'] ?? _uuid.v4(),
                categoryId: itemData['categoryId'],
                subcategoryId: itemData['subcategoryId'],
                itemName: itemData['itemName'],
                manufacturer: itemData['manufacturer'],
                model: itemData['model'],
                quantity: double.parse(itemData['quantity'].toString()),
                unit: itemData['unit'],
              ))
          .toList();

      // Handle image updates
      List<String> updatedImageUrls =
          List.from(existingTender.attachmentUrls ?? []);

      // Delete selected images if requested
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        await _deleteImages(imagesToDelete);
        updatedImageUrls.removeWhere((url) => imagesToDelete.contains(url));
      }

      // Add new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        final newImageUrls =
            await _uploadImages(newImages, existingTender.userId);
        updatedImageUrls.addAll(newImageUrls);
      }

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
        status: newStatus ?? existingTender.status,
        createdAt: existingTender.createdAt,
        items: items,
        attachmentUrls: existingTender.attachmentUrls,
      );

      // Update in Firestore
      await _firestore
          .collection('tenders')
          .doc(id)
          .update(tender.toFirestore());
    } catch (e) {
      print('Error updating tender: $e');
      throw Exception('Failed to update tender: $e');
    }
  }

  // Delete tender
  Future<void> deleteTender(String id) async {
    try {
      // Get the tender first to delete associated attachments and images
      final tender = await fetchTenderById(id);

      // Delete attachments from Storage
      if (tender.attachmentUrls != null && tender.attachmentUrls!.isNotEmpty) {
        await _deleteAttachments(tender.attachmentUrls!);
      }

      // Delete images from Storage
      if (tender.attachmentUrls != null && tender.attachmentUrls!.isNotEmpty) {
        await _deleteImages(tender.attachmentUrls!);
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
      List<String> favoriteTenders =
          List<String>.from(userData['favoriteTenders'] ?? []);

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
  Future<List<Tender>> fetchFavoriteTenders(String userId,
      {TenderStatus? status}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> favoriteTenders =
          List<String>.from(userData['favoriteTenders'] ?? []);

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

        Query query = _firestore
            .collection('tenders')
            .where(FieldPath.documentId, whereIn: batch);

        if (status != null) {
          // Note: We can't combine 'whereIn' and 'where' on different fields in Firestore
          // So we'll need to filter in memory for status
          final snapshot = await query.get();
          final tenders =
              snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();
          results.addAll(tenders.where((tender) => tender.status == status));
        } else {
          final snapshot = await query.get();
          results.addAll(snapshot.docs.map((doc) => Tender.fromFirestore(doc)));
        }
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

      final newValidUntil =
          tender.validUntil.add(Duration(days: additionalWeeks * 7));

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

  // Mark tender as viewed by user
  Future<void> markTenderAsViewed(String tenderId, String userId) async {
    try {
      // First, get the user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      List<String> viewedTenders =
          List<String>.from(userData['viewedTenders'] ?? []);

      // Check if the tender is already marked as viewed
      if (!viewedTenders.contains(tenderId)) {
        viewedTenders.add(tenderId);

        // Update the user document
        await _firestore.collection('users').doc(userId).update({
          'viewedTenders': viewedTenders,
        });
      }
    } catch (e) {
      print('Error marking tender as viewed: $e');
      throw Exception('Failed to mark tender as viewed: $e');
    }
  }

  // Fetch expiring tenders (due to expire in the next X days)
  Future<List<Tender>> fetchExpiringTenders(String userId,
      {int daysThreshold = 3}) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.add(Duration(days: daysThreshold));

      final snapshot = await _firestore
          .collection('tenders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: tenderStatusToString(TenderStatus.open))
          .where('validUntil',
              isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
          .where('validUntil', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      return snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching expiring tenders: $e');
      throw Exception('Failed to fetch expiring tenders: $e');
    }
  }

  // Count tenders by status for a user
  Future<Map<TenderStatus, int>> countUserTendersByStatus(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tenders')
          .where('userId', isEqualTo: userId)
          .get();

      final tenders =
          snapshot.docs.map((doc) => Tender.fromFirestore(doc)).toList();

      // Initialize counters for each status
      final counts = <TenderStatus, int>{
        TenderStatus.open: 0,
        TenderStatus.closed: 0,
        TenderStatus.extended: 0,
      };

      // Count tenders by status
      for (var tender in tenders) {
        counts[tender.status] = (counts[tender.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error counting user tenders by status: $e');
      throw Exception('Failed to count user tenders by status: $e');
    }
  }

  // Upload images specific for Image.network usage
  Future<List<String>> _uploadImages(
      List<dynamic> images, String userId) async {
    List<String> urls = [];
    final ref = _storage.ref().child('tenders/$userId/images/');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != userId) {
      print('User not authenticated or userId mismatch for $userId');
      throw Exception('User not authenticated or userId mismatch');
    }

    print(
        'Starting upload of ${images.length} images to tenders/$userId/images/');

    if (images.isEmpty) {
      print('No images provided for upload');
      return urls;
    }

    for (var image in images) {
      try {
        String fileName;
        if (kIsWeb && image is PlatformFile) {
          fileName = '${_uuid.v4()}_${image.name}';
          final fileRef = ref.child(fileName);
          print('Attempting to upload image: $fileName');

          if (_isImageFile(image.name)) {
            final metadata = SettableMetadata(
              contentType: _getContentType(image.name),
              customMetadata: {'userId': userId},
            );

            final task = fileRef.putData(image.bytes!, metadata);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            print('Generated URL: $url');

            // Використовуємо базовий URL без токена
            final cleanUrl = url.split('?token=')[0];
            print('Clean URL without token: $cleanUrl');
            urls.add(cleanUrl);
          } else {
            print('File is not an image: ${image.name}');
            continue;
          }
        } else {
          // Mobile platform handling
          if (image is io.File) {
            fileName = '${_uuid.v4()}_${image.path.split('/').last}';
            final fileRef = ref.child(fileName);

            // Check if it's an image by extension
            if (_isImageFile(image.path)) {
              try {
                final metadata = SettableMetadata(
                  contentType: _getContentType(image.path),
                  customMetadata: {'userId': userId},
                );

                final task = fileRef.putFile(image, metadata);
                await task.whenComplete(() => null);
                final url = await fileRef.getDownloadURL();
                urls.add(url);
              } catch (e) {
                print('Error in mobile upload of File image: $e');
                continue;
              }
            } else {
              print('File is not an image: ${image.path}');
              continue;
            }
          } else if (image is XFile) {
            // Handle XFile from image_picker
            fileName = '${_uuid.v4()}_${image.name}';
            final fileRef = ref.child(fileName);

            try {
              final file = io.File(image.path);
              final metadata = SettableMetadata(
                contentType: image.mimeType ?? _getContentType(image.name),
                customMetadata: {'userId': userId},
              );

              final task = fileRef.putFile(file, metadata);
              await task.whenComplete(() => null);
              final url = await fileRef.getDownloadURL();
              urls.add(url);
            } catch (e) {
              print('Error in mobile upload of XFile image: $e');
              continue;
            }
          } else {
            print(
                'Unsupported image type for mobile platform: ${image.runtimeType}');
            continue;
          }
        }
      } catch (e, stackTrace) {
        print('Error uploading image ${image.name}: $e');
        print('Stack trace: $stackTrace');
        continue;
      }
    }
    print('Completed upload with ${urls.length} URLs: $urls');
    return urls;
  }

  // Delete images from Storage
  Future<void> _deleteImages(List<String> urls) async {
    for (var url in urls) {
      try {
        // Get the storage reference from the URL
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        print('Error deleting image: $e');
        // Continue with the next image
      }
    }
  }

  // Helper method to check if a file is an image based on its extension
  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg']
        .contains(extension);
  }

  // Helper method to get content type based on file extension
  String _getContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<String>> _uploadAttachments(
      List<dynamic> attachments, String userId) async {
    List<String> urls = [];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw Exception('User not authenticated or userId mismatch');
    }

    final ref = _storage.ref().child('tenders/$userId/attachments/');
    print('Uploading attachments to path: tenders/$userId/attachments/');

    for (var attachment in attachments) {
      try {
        String fileName;
        if (kIsWeb && attachment is PlatformFile) {
          fileName = '${_uuid.v4()}_${attachment.name}';
          final fileRef = ref.child(fileName);
          print('Attempting to upload attachment: $fileName');

          final metadata = SettableMetadata(
            contentType: _getMimeType(attachment.name),
            customMetadata: {'userId': userId},
          );
          final task = fileRef.putData(attachment.bytes!, metadata);
          await task.whenComplete(() => null);
          final url = await fileRef.getDownloadURL();
          print('Generated URL: $url');

          // Зберігаємо URL з ?alt=media, але без токена
          final cleanUrl = url.replaceFirst(
              RegExp(r'\?alt=media&token=[^&]+'), '?alt=media');
          print('Clean URL with alt=media: $cleanUrl');
          urls.add(cleanUrl);
        } else {
          // Обробка для інших платформ
          if (attachment is io.File) {
            fileName = '${_uuid.v4()}_${attachment.path.split('/').last}';
            final fileRef = ref.child(fileName);

            final metadata = SettableMetadata(
              contentType: _getMimeType(attachment.path),
              customMetadata: {'userId': userId},
            );
            final task = fileRef.putFile(attachment, metadata);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            print('Generated URL: $url');

            // Зберігаємо URL з ?alt=media, але без токена
            final cleanUrl = url.replaceFirst(
                RegExp(r'\?alt=media&token=[^&]+'), '?alt=media');
            print('Clean URL with alt=media: $cleanUrl');
            urls.add(cleanUrl);
          } else if (attachment is XFile) {
            fileName = '${_uuid.v4()}_${attachment.name}';
            final fileRef = ref.child(fileName);

            final file = io.File(attachment.path);
            final metadata = SettableMetadata(
              contentType: attachment.mimeType ?? _getMimeType(attachment.name),
              customMetadata: {'userId': userId},
            );
            final task = fileRef.putFile(file, metadata);
            await task.whenComplete(() => null);
            final url = await fileRef.getDownloadURL();
            print('Generated URL: $url');

            // Зберігаємо URL з ?alt=media, але без токена
            final cleanUrl = url.replaceFirst(
                RegExp(r'\?alt=media&token=[^&]+'), '?alt=media');
            print('Clean URL with alt=media: $cleanUrl');
            urls.add(cleanUrl);
          } else {
            print(
                'Unsupported file type for mobile platform: ${attachment.runtimeType}');
            continue;
          }
        }
      } catch (e, stackTrace) {
        print('Error uploading attachment ${attachment.name}: $e');
        print('Stack trace: $stackTrace');
        continue;
      }
    }

    print('Completed upload with ${urls.length} URLs: $urls');
    return urls;
  }

  // Helper method to get MIME type based on file extension
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      default:
        return 'application/octet-stream';
    }
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
