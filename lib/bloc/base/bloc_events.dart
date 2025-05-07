
abstract class BlocEvent {}

// Authentication Events
class AuthLoginEvent extends BlocEvent {
  final String email;
  final String password;

  AuthLoginEvent({required this.email, required this.password});
}

class AuthSignupEvent extends BlocEvent {
  final String email;
  final String password;
  final String name;
  final String phone;

  AuthSignupEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.phone
  });
}

class AuthLogoutEvent extends BlocEvent {}

class AuthUpdateProfileEvent extends BlocEvent {
  final String userId;
  final String name;
  final String phone;
  final dynamic profileImage; // Could be File or web.File

  AuthUpdateProfileEvent({
    required this.userId,
    required this.name,
    required this.phone,
    this.profileImage,
  });
}

// Tender Events
class FetchTendersEvent extends BlocEvent {
  final String? searchQuery;
  final String? city;
  final String? categoryId;
  final bool? userBids;
  final bool? unviewed;

  FetchTendersEvent({
    this.searchQuery,
    this.city,
    this.categoryId,
    this.userBids,
    this.unviewed,
  });
}

class FetchUserTendersEvent extends BlocEvent {}

class FetchTenderByIdEvent extends BlocEvent {
  final String id;

  FetchTenderByIdEvent({required this.id});
}

class CreateTenderEvent extends BlocEvent {
  final String title;
  final String city;
  final double budget;
  final String deliveryOption;
  final int validWeeks;
  final String? description;
  final List<Map<String, dynamic>> items;
  final List<dynamic>? attachments;

  CreateTenderEvent({
    required this.title,
    required this.city,
    required this.budget,
    required this.deliveryOption,
    required this.validWeeks,
    this.description,
    required this.items,
    this.attachments,
  });
}

class UpdateTenderEvent extends BlocEvent {
  final String id;
  final String title;
  final String city;
  final double budget;
  final String deliveryOption;
  final int validWeeks;
  final String? description;
  final List<Map<String, dynamic>> items;

  UpdateTenderEvent({
    required this.id,
    required this.title,
    required this.city,
    required this.budget,
    required this.deliveryOption,
    required this.validWeeks,
    this.description,
    required this.items,
  });
}

class DeleteTenderEvent extends BlocEvent {
  final String id;

  DeleteTenderEvent({required this.id});
}

class ToggleFavoriteTenderEvent extends BlocEvent {
  final String tenderId;

  ToggleFavoriteTenderEvent({required this.tenderId});
}

class FetchFavoriteTendersEvent extends BlocEvent {}

class ExtendTenderEvent extends BlocEvent {
  final String tenderId;
  final int additionalWeeks;

  ExtendTenderEvent({required this.tenderId, required this.additionalWeeks});
}

class CloseTenderEvent extends BlocEvent {
  final String tenderId;

  CloseTenderEvent({required this.tenderId});
}

// Listing Events
class FetchListingsEvent extends BlocEvent {
  final String? searchQuery;
  final String? city;
  final String? categoryId;
  final bool? unviewed;
  final List<String>? deliveryOptions;

  FetchListingsEvent({
    this.searchQuery,
    this.city,
    this.categoryId,
    this.unviewed,
    this.deliveryOptions,
  });
}

class FetchUserListingsEvent extends BlocEvent {}

class FetchListingByIdEvent extends BlocEvent {
  final String id;

  FetchListingByIdEvent({required this.id});
}

class CreateListingEvent extends BlocEvent {
  final String title;
  final String city;
  final String deliveryOption;
  final int validWeeks;
  final String? description;
  final List<Map<String, dynamic>> items;
  final List<dynamic> photos;

  CreateListingEvent({
    required this.title,
    required this.city,
    required this.deliveryOption,
    required this.validWeeks,
    this.description,
    required this.items,
    required this.photos,
  });
}

class UpdateListingEvent extends BlocEvent {
  final String id;
  final String title;
  final String city;
  final String deliveryOption;
  final int validWeeks;
  final String? description;
  final List<Map<String, dynamic>> items;
  final List<String>? photoUrls;

  UpdateListingEvent({
    required this.id,
    required this.title,
    required this.city,
    required this.deliveryOption,
    required this.validWeeks,
    this.description,
    required this.items,
    this.photoUrls,
  });
}

class DeleteListingEvent extends BlocEvent {
  final String id;

  DeleteListingEvent({required this.id});
}

class ToggleFavoriteListingEvent extends BlocEvent {
  final String listingId;

  ToggleFavoriteListingEvent({required this.listingId});
}

class FetchFavoriteListingsEvent extends BlocEvent {}

class MarkListingAsSoldEvent extends BlocEvent {
  final String listingId;

  MarkListingAsSoldEvent({required this.listingId});
}
