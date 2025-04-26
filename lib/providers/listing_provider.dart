import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:construction_marketplace/models/listing.dart';
import 'package:construction_marketplace/models/tender.dart'; // For DeliveryOption enum
import 'package:construction_marketplace/utils/constants.dart';

class ListingProvider with ChangeNotifier {
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
      // For demo purposes, create mock data
      // In a real app, this would make an API call with filters
      await Future.delayed(Duration(seconds: 1));

      _listings = _generateMockListings();

      // Apply filters if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        _listings = _listings.where((listing) =>
        listing.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            listing.description?.toLowerCase().contains(searchQuery.toLowerCase()) == true
        ).toList();
      }

      if (city != null && city.isNotEmpty) {
        _listings = _listings.where((listing) =>
        listing.city.toLowerCase() == city.toLowerCase()
        ).toList();
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        _listings = _listings.where((listing) =>
            listing.items.any((item) => item.categoryId == categoryId)
        ).toList();
      }

      if (deliveryOptions != null && deliveryOptions.isNotEmpty) {
        _listings = _listings.where((listing) =>
            deliveryOptions.contains(listing.deliveryOption.name)
        ).toList();
      }

      notifyListeners();
    } catch (error) {
      print('Error fetching listings: $error');
      rethrow;
    }
  }

  Future<void> fetchUserListings() async {
    if (_authToken == null || _userId == null) {
      return;
    }

    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      _userListings = _generateMockListings().where((listing) => listing.userId == _userId).toList();

      notifyListeners();
    } catch (error) {
      print('Error fetching user listings: $error');
      rethrow;
    }
  }

  Future<Listing> fetchListingById(String id) async {
    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 500));

      final listings = _generateMockListings();
      final listing = listings.firstWhere((l) => l.id == id,
          orElse: () => throw Exception('Listing not found'));

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
    if (_authToken == null || _userId == null) {
      throw Exception('Authentication required.');
    }

    try {
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      final newListing = Listing(
        id: 'listing_${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId!,
        title: title,
        description: description,
        city: city,
        deliveryOption: deliveryOption,
        validUntil: DateTime.now().add(Duration(days: validWeeks * 7)),
        status: ListingStatus.available,
        createdAt: DateTime.now(),
        items: items,
        photoUrls: photos.map((file) => 'mock_url_${file.path.split('/').last}').toList(),
      );

      // Add the new listing to user listings
      _userListings.add(newListing);

      // Also add it to all listings
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
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      // Find the listing to update
      final listingIndex = _userListings.indexWhere((l) => l.id == id);
      if (listingIndex < 0) {
        throw Exception('Listing not found');
      }

      // Create updated listing
      final oldListing = _userListings[listingIndex];
      final updatedListing = Listing(
        id: id,
        userId: oldListing.userId,
        title: title,
        description: description,
        city: city,
        deliveryOption: deliveryOption,
        validUntil: DateTime.now().add(Duration(days: validWeeks * 7)),
        status: oldListing.status,
        createdAt: oldListing.createdAt,
        items: items,
        photoUrls: photoUrls ?? oldListing.photoUrls,
      );

      // Update in user listings
      _userListings[listingIndex] = updatedListing;

      // Update in all listings if it exists there
      final allListingIndex = _listings.indexWhere((l) => l.id == id);
      if (allListingIndex >= 0) {
        _listings[allListingIndex] = updatedListing;
      }

      // Update in favorite listings if it exists there
      final favListingIndex = _favoriteListings.indexWhere((l) => l.id == id);
      if (favListingIndex >= 0) {
        _favoriteListings[favListingIndex] = updatedListing;
      }

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
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

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
      // For demo purposes, just update local data
      // In a real app, this would make an API call
      final isFavorite = _favoriteListings.any((listing) => listing.id == listingId);

      if (isFavorite) {
        // Remove from favorites
        _favoriteListings.removeWhere((listing) => listing.id == listingId);
      } else {
        // Add to favorites
        final listing = _listings.firstWhere(
              (listing) => listing.id == listingId,
          orElse: () async {
            return await fetchListingById(listingId);
          },
        );
        _favoriteListings.add(listing);
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
      // For demo purposes, create mock data
      // In a real app, this would make an API call
      await Future.delayed(Duration(seconds: 1));

      // Just use 2 random listings as favorites for demo
      final allListings = _generateMockListings();
      if (allListings.length >= 2) {
        _favoriteListings = [allListings[0], allListings[1]];
      } else {
        _favoriteListings = allListings;
      }

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
      // For demo purposes, just update local data
      // In a real app, this would make an API call

      // Update in user listings
      final userListingIndex = _userListings.indexWhere((l) => l.id == listingId);
      if (userListingIndex >= 0) {
        final listing = _userListings[userListingIndex];
        final updatedListing = Listing(
          id: listing.id,
          userId: listing.userId,
          title: listing.title,
          description: listing.description,
          city: listing.city,
          deliveryOption: listing.deliveryOption,
          validUntil: listing.validUntil,
          status: ListingStatus.sold,
          createdAt: listing.createdAt,
          items: listing.items,
          photoUrls: listing.photoUrls,
        );

        _userListings[userListingIndex] = updatedListing;

        // Update in all listings if it exists there
        final allListingIndex = _listings.indexWhere((l) => l.id == listingId);
        if (allListingIndex >= 0) {
          _listings[allListingIndex] = updatedListing;
        }

        // Update in favorite listings if it exists there
        final favListingIndex = _favoriteListings.indexWhere((l) => l.id == listingId);
        if (favListingIndex >= 0) {
          _favoriteListings[favListingIndex] = updatedListing;
        }

        notifyListeners();
      }
    } catch (error) {
      print('Error marking listing as sold: $error');
      rethrow;
    }
  }

  // Helper method to generate mock listings for demo
  List<Listing> _generateMockListings() {
    return [
      Listing(
        id: 'listing1',
        userId: 'user1',
        title: 'Premium Hardwood Flooring - Clearance Sale',
        description: 'Leftover premium oak hardwood flooring from a completed project. In excellent condition.',
        city: 'Toronto, ON',
        deliveryOption: DeliveryOption.pickup,
        validUntil: DateTime.now().add(Duration(days: 14)),
        status: ListingStatus.available,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        items: [
          ListingItem(
            id: 'item1',
            categoryId: 'Floors & Area Rugs',
            subcategoryId: 'Hardwood Flooring',
            itemName: 'Oak Hardwood Flooring',
            manufacturer: 'Bruce',
            model: 'Natural Reflections',
            quantity: 75,
            unit: 'sq.m',
            price: 35.00,
            isFree: false,
          ),
        ],
        photoUrls: [
          'https://images.unsplash.com/photo-1573890339642-6b7a7edf6f54',
          'https://images.unsplash.com/photo-1584467541268-b040f83be3fd',
        ],
      ),
      Listing(
        id: 'listing2',
        userId: 'user2',
        title: 'Various Construction Tools - Great Condition',
        description: 'Selling various construction tools in great condition. All tools well maintained and work perfectly.',
        city: 'Vancouver, BC',
        deliveryOption: DeliveryOption.discuss,
        validUntil: DateTime.now().add(Duration(days: 21)),
        status: ListingStatus.available,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        items: [
          ListingItem(
            id: 'item2',
            categoryId: 'Tools',
            subcategoryId: 'Power Tools',
            itemName: 'Cordless Drill',
            manufacturer: 'DeWalt',
            model: 'DCD777C2',
            quantity: 1,
            unit: 'pcs',
            price: 80.00,
            isFree: false,
          ),
          ListingItem(
            id: 'item3',
            categoryId: 'Tools',
            subcategoryId: 'Hand Tools',
            itemName: 'Hammer Set',
            manufacturer: 'Stanley',
            model: null,
            quantity: 3,
            unit: 'pcs',
            price: 25.00,
            isFree: false,
          ),
        ],
        photoUrls: [
          'https://images.unsplash.com/photo-1530124566582-a618bc2615dc',
          'https://images.unsplash.com/photo-1572981739196-acc9171982c9',
        ],
      ),
      Listing(
        id: 'listing3',
        userId: 'user3',
        title: 'Free Kitchen Cabinet Handles - Renovation Leftovers',
        description: 'Giving away unused kitchen cabinet handles from recent renovation. Still in original packaging.',
        city: 'Montreal, QC',
        deliveryOption: DeliveryOption.pickup,
        validUntil: DateTime.now().add(Duration(days: 10)),
        status: ListingStatus.available,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        items: [
          ListingItem(
            id: 'item4',
            categoryId: 'Hardware',
            subcategoryId: 'Cabinet & Furniture Hardware',
            itemName: 'Stainless Steel Cabinet Handles',
            manufacturer: null,
            model: null,
            quantity: 20,
            unit: 'pcs',
            price: null,
            isFree: true,
          ),
        ],
        photoUrls: [
          'https://images.unsplash.com/photo-1595428774223-ef52624120d2',
        ],
      ),
      Listing(
        id: 'listing4',
        userId: _userId ?? 'user4',
        title: 'Extra Paint and Supplies - Half Price',
        description: 'Selling leftover interior paint and supplies from completed renovation. Less than half price of retail.',
        city: 'Calgary, AB',
        deliveryOption: DeliveryOption.delivery,
        validUntil: DateTime.now().add(Duration(days: 28)),
        status: ListingStatus.available,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        items: [
          ListingItem(
            id: 'item5',
            categoryId: 'Paint',
            subcategoryId: 'Interior Paint',
            itemName: 'Premium Interior Paint - Eggshell Finish',
            manufacturer: 'Benjamin Moore',
            model: 'Regal Select',
            quantity: 4,
            unit: 'liter',
            price: 30.00,
            isFree: false,
          ),
          ListingItem(
            id: 'item6',
            categoryId: 'Paint',
            subcategoryId: 'Painting Tools & Supplies',
            itemName: 'Paint Roller Kit',
            manufacturer: null,
            model: null,
            quantity: 2,
            unit: 'pcs',
            price: 15.00,
            isFree: false,
          ),
        ],
        photoUrls: [
          'https://images.unsplash.com/photo-1589939705384-5185137a7f0f',
          'https://images.unsplash.com/photo-1584187273618-6c38a0c31285',
        ],
      ),
    ];
  }
}