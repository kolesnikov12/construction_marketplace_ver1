import 'dart:io';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/tender.dart';
import '../models/tender_item.dart';
import '../repositorties/tender_repository.dart';

class TenderProvider with ChangeNotifier {
  final TenderRepository _tenderRepository = TenderRepository();

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
      final fetchedTenders = await _tenderRepository.fetchTenders(
        searchQuery: searchQuery,
        city: city,
        categoryId: categoryId,
        userBids: userBids,
        unviewed: unviewed,
        userId: _userId,
      );

      _tenders = fetchedTenders;
      notifyListeners();
    } catch (error) {
      print('Error fetching tenders: $error');
      rethrow;
    }
  }

  Future<void> fetchUserTenders() async {
    if (_userId == null) {
      return;
    }

    try {
      final fetchedTenders = await _tenderRepository.fetchUserTenders(_userId!);
      _userTenders = fetchedTenders;
      notifyListeners();
    } catch (error) {
      print('Error fetching user tenders: $error');
      rethrow;
    }
  }

  Future<Tender> fetchTenderById(String id) async {
    try {
      final tender = await _tenderRepository.fetchTenderById(id);
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
    if (_userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      final itemsData = items.map((item) => {
        'categoryId': item.categoryId,
        'subcategoryId': item.subcategoryId,
        'itemName': item.itemName,
        'manufacturer': item.manufacturer,
        'model': item.model,
        'quantity': item.quantity,
        'unit': item.unit,
      }).toList();

      final newTender = await _tenderRepository.createTender(
        userId: _userId!,
        title: title,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validWeeks: validWeeks,
        description: description,
        itemsData: itemsData,
        attachments: attachments,
      );

      // Update local lists
      _userTenders.insert(0, newTender);
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
      final itemsData = items.map((item) => {
        'id': item.id,
        'categoryId': item.categoryId,
        'subcategoryId': item.subcategoryId,
        'itemName': item.itemName,
        'manufacturer': item.manufacturer,
        'model': item.model,
        'quantity': item.quantity,
        'unit': item.unit,
      }).toList();

      await _tenderRepository.updateTender(
        id: id,
        title: title,
        city: city,
        budget: budget,
        deliveryOption: deliveryOption,
        validWeeks: validWeeks,
        description: description,
        itemsData: itemsData,
      );

      // Update the tender in local lists
      await _refreshTenderInLists(id);

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
      await _tenderRepository.deleteTender(id);

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
      final isFavorite = await _tenderRepository.toggleFavoriteTender(tenderId, _userId!);

      if (isFavorite) {
        // Add to favorites if not already there
        if (!_favoriteTenders.any((t) => t.id == tenderId)) {
          final tender = await fetchTenderById(tenderId);
          _favoriteTenders.add(tender);
        }
      } else {
        // Remove from favorites
        _favoriteTenders.removeWhere((tender) => tender.id == tenderId);
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
      final fetchedTenders = await _tenderRepository.fetchFavoriteTenders(_userId!);
      _favoriteTenders = fetchedTenders;
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
      await _tenderRepository.extendTender(tenderId, additionalWeeks);

      // Update the tender in local lists
      await _refreshTenderInLists(tenderId);

      notifyListeners();
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
      await _tenderRepository.closeTender(tenderId);

      // Update the tender in local lists
      await _refreshTenderInLists(tenderId);

      notifyListeners();
    } catch (error) {
      print('Error closing tender: $error');
      rethrow;
    }
  }

  // Helper method to refresh a tender in all lists
  Future<void> _refreshTenderInLists(String tenderId) async {
    try {
      final updatedTender = await _tenderRepository.fetchTenderById(tenderId);

      // Update in all lists if found
      final userTenderIndex = _userTenders.indexWhere((t) => t.id == tenderId);
      if (userTenderIndex >= 0) {
        _userTenders[userTenderIndex] = updatedTender;
      }

      final allTenderIndex = _tenders.indexWhere((t) => t.id == tenderId);
      if (allTenderIndex >= 0) {
        _tenders[allTenderIndex] = updatedTender;
      }

      final favTenderIndex = _favoriteTenders.indexWhere((t) => t.id == tenderId);
      if (favTenderIndex >= 0) {
        _favoriteTenders[favTenderIndex] = updatedTender;
      }
    } catch (e) {
      print('Error refreshing tender in lists: $e');
    }
  }
}