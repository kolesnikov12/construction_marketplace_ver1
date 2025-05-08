import '../repositorties/listing_repository.dart';
import 'base/bloc_base.dart';
import 'base/bloc_events.dart';
import 'base/bloc_states.dart';
import '../models/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListingBloc extends Bloc {
  final ListingRepository _listingRepository = ListingRepository();

  @override
  void handleEvent(BlocEvent event) async {
    if (event is FetchListingsEvent) {
      await _handleFetchListings(event);
    } else if (event is FetchUserListingsEvent) {
      await _handleFetchUserListings();
    } else if (event is FetchListingByIdEvent) {
      await _handleFetchListingById(event);
    } else if (event is CreateListingEvent) {
      await _handleCreateListing(event);
    } else if (event is UpdateListingEvent) {
      await _handleUpdateListing(event);
    } else if (event is DeleteListingEvent) {
      await _handleDeleteListing(event);
    } else if (event is ToggleFavoriteListingEvent) {
      await _handleToggleFavoriteListing(event);
    } else if (event is FetchFavoriteListingsEvent) {
      await _handleFetchFavoriteListings();
    } else if (event is MarkListingAsSoldEvent) {
      await _handleMarkListingAsSold(event);
    }
  }

  Future<void> _handleFetchListings(FetchListingsEvent event) async {
    emitState(LoadingState());

    try {
      final listings = await _listingRepository.fetchListings(
        searchQuery: event.searchQuery,
        city: event.city,
        categoryId: event.categoryId,
        unviewed: event.unviewed,
        deliveryOptions: event.deliveryOptions,
      );

      emitState(ListingsLoadedState(listings: listings));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchUserListings() async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();
      final listings = await _listingRepository.fetchUserListings(userId);

      emitState(UserListingsLoadedState(listings: listings));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchListingById(FetchListingByIdEvent event) async {
    emitState(LoadingState());

    try {
      final listing = await _listingRepository.fetchListingById(event.id);
      emitState(ListingDetailsLoadedState(listing: listing));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleCreateListing(CreateListingEvent event) async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();

      final listing = await _listingRepository.createListing(
        userId: userId,
        title: event.title,
        city: event.city,
        deliveryOption: stringToDeliveryOption(event.deliveryOption),
        validWeeks: event.validWeeks,
        description: event.description,
        itemsData: event.items,
        photos: event.photos,
      );

      emitState(ListingCreatedState(listing: listing));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleUpdateListing(UpdateListingEvent event) async {
    emitState(LoadingState());

    try {
      await _listingRepository.updateListing(
        id: event.id,
        title: event.title,
        city: event.city,
        deliveryOption: stringToDeliveryOption(event.deliveryOption),
        validWeeks: event.validWeeks,
        description: event.description,
        itemsData: event.items,
        photoUrls: event.photoUrls,
      );

      emitState(ListingUpdatedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleDeleteListing(DeleteListingEvent event) async {
    emitState(LoadingState());

    try {
      await _listingRepository.deleteListing(event.id);
      emitState(ListingDeletedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleToggleFavoriteListing(
      ToggleFavoriteListingEvent event) async {
    try {
      final userId = await _getCurrentUserId();
      final isFavorite = await _listingRepository.toggleFavoriteListing(
          event.listingId, userId);

      emitState(ListingFavoriteToggledState(isFavorite: isFavorite));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchFavoriteListings() async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();
      final listings = await _listingRepository.fetchFavoriteListings(userId);

      emitState(FavoriteListingsLoadedState(listings: listings));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleMarkListingAsSold(MarkListingAsSoldEvent event) async {
    emitState(LoadingState());

    try {
      await _listingRepository.markListingAsSold(event.listingId);
      emitState(ListingMarkedAsSoldState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  // Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }
}