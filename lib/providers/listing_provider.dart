import 'dart:io';
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/listing.dart';
import '../models/listing_item.dart';
import '../repositorties/listing_repository.dart';

class ListingProvider with ChangeNotifier {
  final ListingRepository _listingRepository = ListingRepository();

  List<Listing> _listings = [];
  List<Listing> _userListings = [];
  List<Listing> _favoriteListings = [];
  String? _authToken;
  String? _userId;

  void update(String? token, String? userId) {
    _authToken = token;
    _userId = userId;
  }

  List<Listing> get listings {
    return [..._listings];
  }

  List<Listing> get userListings {
    return [..._userListings];
  }

  List<Listing> get favoriteListings {
    return [..._favoriteListings];
  }

  Future<void> fetchListings({
    String? searchQuery,
    String? city,
    String? categoryId,
    bool? unviewed,
    List<String>? deliveryOptions,
  }) async {
    try {
      final fetchedListings = await _listingRepository.fetchListings(
        searchQuery: searchQuery,
        city: city,
        categoryId: categoryId,
        unviewed: unviewed,
        deliveryOptions: deliveryOptions,
      );

      _listings = fetchedListings;
      notifyListeners();
    } catch (error) {
      print('Error fetching listings: $error');
      rethrow;
    }
  }

  Future<void> fetchUserListings() async {
    if (_userId == null) {
      return;
    }

    try {
      final fetchedListings = await _listingRepository.fetchUserListings(_userId!);
      _userListings = fetchedListings;
      notifyListeners();
    } catch (error) {
      print('Error fetching user listings: $error');
      rethrow;
    }
  }

  Future<Listing> fetchListingById(String id) async {
    try {
      final listing = await _listingRepository.fetchListingById(id);
      return listing;
    } catch (error) {
      print('Error fetching listing details: $error');
      rethrow;
    }
  }

  Future<Listing> createListing({
    required String title,
    required String city,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<ListingItem> items,
    required List<File> photos,
  }) async {
    if (_userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      // Convert ListingItems to Map for repository
      final itemsData = items.map((item) => {
        'categoryId': item.categoryId,
        'subcategoryId': item.subcategoryId,
        'itemName': item.itemName,
        'manufacturer': item.manufacturer,
        'model': item.model,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'isFree': item.isFree,
      }).toList();

      final newListing = await _listingRepository.createListing(
        userId: _userId!,
        title: title,
        city: city,
        deliveryOption: deliveryOption,
        validWeeks: validWeeks,
        description: description,
        itemsData: itemsData,
        photos: photos,
      );

      // Add the new listing to local lists
      _userListings.insert(0, newListing);
      _listings.insert(0, newListing);
      notifyListeners();

      return newListing;
    } catch (error) {
      print('Error creating listing: $error');
      rethrow;
    }
  }

  Future<void> updateListing({
    required String id,
    required String title,
    required String city,
    required DeliveryOption deliveryOption,
    required int validWeeks,
    String? description,
    required List<ListingItem> items,
    List<String>? photoUrls,
  }) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      // Convert ListingItems to Map for repository
      final itemsData = items.map((item) => {
        'id': item.id,
        'categoryId': item.categoryId,
        'subcategoryId': item.subcategoryId,
        'itemName': item.itemName,
        'manufacturer': item.manufacturer,
        'model': item.model,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'isFree': item.isFree,
      }).toList();

      await _listingRepository.updateListing(
        id: id,
        title: title,
        city: city,
        deliveryOption: deliveryOption,
        validWeeks: validWeeks,
        description: description,
        itemsData: itemsData,
        photoUrls: photoUrls,
      );

      // Refresh the listing in local lists
      await _refreshListingInLists(id);
      notifyListeners();
    } catch (error) {
      print('Error updating listing: $error');
      rethrow;
    }
  }

  Future<void> deleteListing(String id) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      await _listingRepository.deleteListing(id);

      // Remove from all lists
      _userListings.removeWhere((listing) => listing.id == id);
      _listings.removeWhere((listing) => listing.id == id);
      _favoriteListings.removeWhere((listing) => listing.id == id);

      notifyListeners();
    } catch (error) {
      print('Error deleting listing: $error');
      rethrow;
    }
  }

  Future<void> toggleFavoriteListing(String listingId) async {
    if (_authToken == null || _userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      final isFavorite = await _listingRepository.toggleFavoriteListing(listingId, _userId!);

      if (isFavorite) {
        // Add to favorites if not already there
        if (!_favoriteListings.any((listing) => listing.id == listingId)) {
          final listing = await fetchListingById(listingId);
          _favoriteListings.add(listing);
        }
      } else {
        // Remove from favorites
        _favoriteListings.removeWhere((listing) => listing.id == listingId);
      }

      notifyListeners();
    } catch (error) {
      print('Error toggling favorite: $error');
      rethrow;
    }
  }

  Future<void> fetchFavoriteListings() async {
    if (_authToken == null || _userId == null) {
      return;
    }

    try {
      final fetchedListings = await _listingRepository.fetchFavoriteListings(_userId!);
      _favoriteListings = fetchedListings;
      notifyListeners();
    } catch (error) {
      print('Error fetching favorite listings: $error');
      rethrow;
    }
  }

  Future<void> markListingAsSold(String listingId) async {
    if (_authToken == null) {
      throw Exception('Authentication required.');
    }

    try {
      await _listingRepository.markListingAsSold(listingId);

      // Refresh the listing in all lists
      await _refreshListingInLists(listingId);
      notifyListeners();
    } catch (error) {
      print('Error marking listing as sold: $error');
      rethrow;
    }
  }

  // Helper method to refresh a listing in all lists
  Future<void> _refreshListingInLists(String listingId) async {
    try {
      final updatedListing = await _listingRepository.fetchListingById(listingId);

      // Update in all lists if found
      final userListingIndex = _userListings.indexWhere((listing) => listing.id == listingId);
      if (userListingIndex >= 0) {
        _userListings[userListingIndex] = updatedListing;
      }

      final allListingIndex = _listings.indexWhere((listing) => listing.id == listingId);
      if (allListingIndex >= 0) {
        _listings[allListingIndex] = updatedListing;
      }

      final favListingIndex = _favoriteListings.indexWhere((listing) => listing.id == listingId);
      if (favListingIndex >= 0) {
        _favoriteListings[favListingIndex] = updatedListing;
      }
    } catch (e) {
      print('Error refreshing listing in lists: $e');
    }
  }
}