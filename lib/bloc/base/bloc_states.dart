abstract class BlocState {}

class InitialState extends BlocState {}

class LoadingState extends BlocState {}

class ErrorState extends BlocState {
  final String message;

  ErrorState({required this.message});
}

// Authentication States
class AuthenticatedState extends BlocState {
  final dynamic user;
  final String token;

  AuthenticatedState({required this.user, required this.token});
}

class UnauthenticatedState extends BlocState {}

class AuthenticatingState extends BlocState {}

class RegisteringState extends BlocState {}

class EmailUnverifiedState extends BlocState {}

class ProfileUpdatedState extends BlocState {
  final dynamic user;

  ProfileUpdatedState({required this.user});
}

// Tender States
class TendersLoadedState extends BlocState {
  final List<dynamic> tenders;

  TendersLoadedState({required this.tenders});
}

class UserTendersLoadedState extends BlocState {
  final List<dynamic> tenders;

  UserTendersLoadedState({required this.tenders});
}

class TenderDetailsLoadedState extends BlocState {
  final dynamic tender;

  TenderDetailsLoadedState({required this.tender});
}

class TenderCreatedState extends BlocState {
  final dynamic tender;

  TenderCreatedState({required this.tender});
}

class TenderUpdatedState extends BlocState {}

class TenderDeletedState extends BlocState {}

class FavoriteTendersLoadedState extends BlocState {
  final List<dynamic> tenders;

  FavoriteTendersLoadedState({required this.tenders});
}

class TenderFavoriteToggledState extends BlocState {
  final bool isFavorite;

  TenderFavoriteToggledState({required this.isFavorite});
}

class TenderExtendedState extends BlocState {}

class TenderClosedState extends BlocState {}

// Listing States
class ListingsLoadedState extends BlocState {
  final List<dynamic> listings;

  ListingsLoadedState({required this.listings});
}

class UserListingsLoadedState extends BlocState {
  final List<dynamic> listings;

  UserListingsLoadedState({required this.listings});
}

class ListingDetailsLoadedState extends BlocState {
  final dynamic listing;

  ListingDetailsLoadedState({required this.listing});
}

class ListingCreatedState extends BlocState {
  final dynamic listing;

  ListingCreatedState({required this.listing});
}

class ListingUpdatedState extends BlocState {}

class ListingDeletedState extends BlocState {}

class FavoriteListingsLoadedState extends BlocState {
  final List<dynamic> listings;

  FavoriteListingsLoadedState({required this.listings});
}

class ListingFavoriteToggledState extends BlocState {
  final bool isFavorite;

  ListingFavoriteToggledState({required this.isFavorite});
}

class ListingMarkedAsSoldState extends BlocState {}
