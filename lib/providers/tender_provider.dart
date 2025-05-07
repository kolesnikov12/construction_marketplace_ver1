import 'dart:io';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/tender.dart';
import '../models/tender_item.dart';

class TenderProvider with ChangeNotifier {
  List<Tender> _tenders = [];
  List<Tender> _userTenders = [];
  List<Tender> _favoriteTenders = [];
  String? _authToken;
  String? _userId;

  void update(String? token, String? userId) {
    _authToken = token;
    _userId = userId;
  }

  List<Tender> get tenders {
    return [..._tenders];
  }

  List<Tender> get userTenders {
    return [..._userTenders];
  }

  List<Tender> get favoriteTenders {
    return [..._favoriteTenders];
  }

  Future<void> fetchTenders({
    String? searchQuery,
    String? city,
    String? categoryId,
    bool? userBids,
    bool? unviewed,
  }) async {
    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call with filters
      await Future.delayed(Duration(seconds: 1));

      _tenders = _generateMockTenders();

      // Apply filters if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        _tenders = _tenders
            .where((tender) =>
                tender.title
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                tender.description
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ==
                    true)
            .toList();
      }

      if (city != null && city.isNotEmpty) {
        _tenders = _tenders
            .where((tender) => tender.city.toLowerCase() == city.toLowerCase())
            .toList();
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        _tenders = _tenders
            .where((tender) =>
                tender.items.any((item) => item.categoryId == categoryId))
            .toList();
      }

      notifyListeners();
    } catch (error) {
      print('Error fetching tenders: $error');
      rethrow;
    }
  }

  Future<void> fetchUserTenders() async {
    if (_authToken == null || _userId == null) {
      return;
    }

    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      _userTenders = _generateMockTenders()
          .where((tender) => tender.userId == _userId)
          .toList();

      notifyListeners();
    } catch (error) {
      print('Error fetching user tenders: $error');
      rethrow;
    }
  }

  Future<Tender> fetchTenderById(String id) async {
    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 500));

      final tenders = _generateMockTenders();
      final tender = tenders.firstWhere((t) => t.id == id,
          orElse: () => throw Exception('Tender not found'));

      return tender;
    } catch (error) {
      print('Error fetching tender details: $error');
      rethrow;
    }
  }

  Future<Tender> createTender({
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<TenderItem> items,
    List<File>? attachments,
  }) async {
    if (_authToken == null || _userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      final newTender = Tender(
        id: 'tender_${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId!,
        title: title,
        description: description,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validUntil: DateTime.now().add(Duration(days: validWeeks * 7)),
        status: TenderStatus.open,
        createdAt: DateTime.now(),
        items: items,
        attachmentUrls: attachments
            ?.map((file) => 'mock_url_${file.path.split('/').last}')
            .toList(),
      );

      // Add the new tender to user tenders
      _userTenders.add(newTender);

      // Also add it to all tenders
      _tenders.insert(0, newTender);

      notifyListeners();

      return newTender;
    } catch (error) {
      print('Error creating tender: $error');
      rethrow;
    }
  }

  Future<void> updateTender({
    required String id,
    required String title,
    required String city,
    required double budget,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<TenderItem> items,
  }) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      // Find the tender to update
      final tenderIndex = _userTenders.indexWhere((t) => t.id == id);
      if (tenderIndex < 0) {
        throw Exception('Tender not found');
      }

      // Create updated tender
      final oldTender = _userTenders[tenderIndex];
      final updatedTender = Tender(
        id: id,
        userId: oldTender.userId,
        title: title,
        description: description,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validUntil: DateTime.now().add(Duration(days: validWeeks * 7)),
        status: oldTender.status,
        createdAt: oldTender.createdAt,
        items: items,
        attachmentUrls: oldTender.attachmentUrls,
      );

      // Update in user tenders
      _userTenders[tenderIndex] = updatedTender;

      // Update in all tenders if it exists there
      final allTenderIndex = _tenders.indexWhere((t) => t.id == id);
      if (allTenderIndex >= 0) {
        _tenders[allTenderIndex] = updatedTender;
      }

      // Update in favorite tenders if it exists there
      final favTenderIndex = _favoriteTenders.indexWhere((t) => t.id == id);
      if (favTenderIndex >= 0) {
        _favoriteTenders[favTenderIndex] = updatedTender;
      }

      notifyListeners();
    } catch (error) {
      print('Error updating tender: $error');
      rethrow;
    }
  }

  Future<void> deleteTender(String id) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      // Remove from all lists
      _userTenders.removeWhere((tender) => tender.id == id);
      _tenders.removeWhere((tender) => tender.id == id);
      _favoriteTenders.removeWhere((tender) => tender.id == id);

      notifyListeners();
    } catch (error) {
      print('Error deleting tender: $error');
      rethrow;
    }
  }

  Future<void> toggleFavoriteTender(String tenderId) async {
    if (_authToken == null || _userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      final isFavorite =
          _favoriteTenders.any((tender) => tender.id == tenderId);

      if (isFavorite) {
        // Remove from favorites
        _favoriteTenders.removeWhere((tender) => tender.id == tenderId);
      } else {
        // Add to favorites
        try {
          final listing =
              _tenders.firstWhere((listing) => listing.id == tenderId);
          _favoriteTenders.add(listing);
        } catch (_) {
          // Не знайдено в локальних списках, завантажуємо
          final listing = await fetchTenderById(tenderId);
          _favoriteTenders.add(listing);
        }
      }

      notifyListeners();
    } catch (error) {
      print('Error toggling favorite: $error');
      rethrow;
    }
  }

  Future<void> fetchFavoriteTenders() async {
    if (_authToken == null || _userId == null) {
      return;
    }

    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      // Just use 2 random tenders as favorites for demo
      final allTenders = _generateMockTenders();
      if (allTenders.length >= 2) {
        _favoriteTenders = [allTenders[0], allTenders[1]];
      } else {
        _favoriteTenders = allTenders;
      }

      notifyListeners();
    } catch (error) {
      print('Error fetching favorite tenders: $error');
      rethrow;
    }
  }

  Future<void> extendTender(String tenderId, int additionalWeeks) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, just update local data
      // In a real app, this would make an API call

      // Update in user tenders
      final userTenderIndex = _userTenders.indexWhere((t) => t.id == tenderId);
      if (userTenderIndex >= 0) {
        final tender = _userTenders[userTenderIndex];
        final updatedTender = Tender(
          id: tender.id,
          userId: tender.userId,
          title: tender.title,
          description: tender.description,
          city: tender.city,
          budget: tender.budget,
          deliveryOption: tender.deliveryOption,
          validUntil:
              tender.validUntil.add(Duration(days: additionalWeeks * 7)),
          status: TenderStatus.extended,
          createdAt: tender.createdAt,
          items: tender.items,
          attachmentUrls: tender.attachmentUrls,
        );

        _userTenders[userTenderIndex] = updatedTender;

        // Update in all tenders if it exists there
        final allTenderIndex = _tenders.indexWhere((t) => t.id == tenderId);
        if (allTenderIndex >= 0) {
          _tenders[allTenderIndex] = updatedTender;
        }

        // Update in favorite tenders if it exists there
        final favTenderIndex =
            _favoriteTenders.indexWhere((t) => t.id == tenderId);
        if (favTenderIndex >= 0) {
          _favoriteTenders[favTenderIndex] = updatedTender;
        }

        notifyListeners();
      }
    } catch (error) {
      print('Error extending tender: $error');
      rethrow;
    }
  }

  Future<void> closeTender(String tenderId) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, just update local data
      // In a real app, this would make an API call

      // Update in user tenders
      final userTenderIndex = _userTenders.indexWhere((t) => t.id == tenderId);
      if (userTenderIndex >= 0) {
        final tender = _userTenders[userTenderIndex];
        final updatedTender = Tender(
          id: tender.id,
          userId: tender.userId,
          title: tender.title,
          description: tender.description,
          city: tender.city,
          budget: tender.budget,
          deliveryOption: tender.deliveryOption,
          validUntil: tender.validUntil,
          status: TenderStatus.closed,
          createdAt: tender.createdAt,
          items: tender.items,
          attachmentUrls: tender.attachmentUrls,
        );

        _userTenders[userTenderIndex] = updatedTender;

        // Update in all tenders if it exists there
        final allTenderIndex = _tenders.indexWhere((t) => t.id == tenderId);
        if (allTenderIndex >= 0) {
          _tenders[allTenderIndex] = updatedTender;
        }

        // Update in favorite tenders if it exists there
        final favTenderIndex =
            _favoriteTenders.indexWhere((t) => t.id == tenderId);
        if (favTenderIndex >= 0) {
          _favoriteTenders[favTenderIndex] = updatedTender;
        }

        notifyListeners();
      }
    } catch (error) {
      print('Error closing tender: $error');
      rethrow;
    }
  }

  // Helper method to generate mock tenders for demo
  List<Tender> _generateMockTenders() {
    return [
      Tender(
        id: 'tender1',
        userId: 'user1',
        title: 'Need Quality Lumber for Home Renovation',
        description:
            'Looking for premium quality lumber for a complete home renovation project. Need various sizes and types.',
        city: 'Toronto, ON',
        budget: 2500.00,
        deliveryOption: DeliveryOption.pickup,
        validUntil: DateTime.now().add(Duration(days: 14)),
        status: TenderStatus.open,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        items: [
          TenderItem(
            id: 'item1',
            categoryId: 'Building Materials',
            subcategoryId: 'Lumber & Composites',
            itemName: '2x4 Pressure Treated Lumber',
            manufacturer: null,
            model: null,
            quantity: 50,
            unit: 'pcs',
          ),
          TenderItem(
            id: 'item2',
            categoryId: 'Building Materials',
            subcategoryId: 'Lumber & Composites',
            itemName: '4x8 Plywood Sheets',
            manufacturer: null,
            model: null,
            quantity: 20,
            unit: 'pcs',
          ),
        ],
      ),
      Tender(
        id: 'tender2',
        userId: 'user2',
        title: 'Kitchen Renovation Materials Needed',
        description:
            'Complete kitchen renovation project. Looking for cabinets, countertops, and appliances.',
        city: 'Vancouver, BC',
        budget: 8000.00,
        deliveryOption: DeliveryOption.delivery,
        validUntil: DateTime.now().add(Duration(days: 21)),
        status: TenderStatus.open,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        items: [
          TenderItem(
            id: 'item3',
            categoryId: 'Kitchen',
            subcategoryId: 'Kitchen Cabinets',
            itemName: 'White Shaker Cabinets',
            manufacturer: null,
            model: null,
            quantity: 10,
            unit: 'pcs',
          ),
          TenderItem(
            id: 'item4',
            categoryId: 'Kitchen',
            subcategoryId: 'Countertops & Backsplashes',
            itemName: 'Granite Countertop',
            manufacturer: null,
            model: null,
            quantity: 25,
            unit: 'sq.m',
          ),
          TenderItem(
            id: 'item5',
            categoryId: 'Appliances',
            subcategoryId: 'Refrigerators',
            itemName: 'French Door Refrigerator',
            manufacturer: 'Samsung',
            model: 'RF28R7351SR',
            quantity: 1,
            unit: 'pcs',
          ),
        ],
      ),
      Tender(
        id: 'tender3',
        userId: 'user3',
        title: 'Bathroom Fixtures Needed',
        description:
            'Renovating two bathrooms in a residential property. Need various fixtures and materials.',
        city: 'Montreal, QC',
        budget: 3500.00,
        deliveryOption: DeliveryOption.discuss,
        validUntil: DateTime.now().add(Duration(days: 10)),
        status: TenderStatus.open,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        items: [
          TenderItem(
            id: 'item6',
            categoryId: 'Bath',
            subcategoryId: 'Bathroom Faucets',
            itemName: 'Single Handle Bathroom Faucet',
            manufacturer: 'Moen',
            model: 'Adler',
            quantity: 2,
            unit: 'pcs',
          ),
          TenderItem(
            id: 'item7',
            categoryId: 'Bath',
            subcategoryId: 'Toilets & Bidets',
            itemName: 'Dual Flush Toilet',
            manufacturer: 'American Standard',
            model: 'Studio',
            quantity: 2,
            unit: 'pcs',
          ),
          TenderItem(
            id: 'item8',
            categoryId: 'Bath',
            subcategoryId: 'Bathroom Vanities',
            itemName: '36-inch Bathroom Vanity',
            manufacturer: null,
            model: null,
            quantity: 2,
            unit: 'pcs',
          ),
        ],
      ),
      Tender(
        id: 'tender4',
        userId: _userId ?? 'user4',
        title: 'Flooring Materials for Office Building',
        description:
            'Need quality flooring materials for a 500 sq.m office space renovation.',
        city: 'Calgary, AB',
        budget: 7500.00,
        deliveryOption: DeliveryOption.delivery,
        validUntil: DateTime.now().add(Duration(days: 28)),
        status: TenderStatus.open,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        items: [
          TenderItem(
            id: 'item9',
            categoryId: 'Floors & Area Rugs',
            subcategoryId: 'Laminate Flooring',
            itemName: 'Commercial Grade Laminate Flooring',
            manufacturer: null,
            model: null,
            quantity: 500,
            unit: 'sq.m',
          ),
          TenderItem(
            id: 'item10',
            categoryId: 'Floors & Area Rugs',
            subcategoryId: 'Vinyl Flooring',
            itemName: 'Luxury Vinyl Planks',
            manufacturer: null,
            model: null,
            quantity: 100,
            unit: 'sq.m',
          ),
        ],
      ),
    ];
  }
}
