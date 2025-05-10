import 'package:shared_preferences/shared_preferences.dart';

import '../repositorties/tender_repository.dart';
import '../repositorties/user_repository.dart';
import 'base/bloc_base.dart';
import 'base/bloc_events.dart';
import 'base/bloc_states.dart';
import '../models/enums.dart';

class TenderBloc extends Bloc {
  final TenderRepository _tenderRepository = TenderRepository();
  final UserRepository _userRepository;

  TenderBloc(this._userRepository);

  void handleEvent(BlocEvent event) async {
    if (event is FetchTendersEvent) {
      await _handleFetchTenders(event);
    } else if (event is FetchUserTendersEvent) {
      await _handleFetchUserTenders();
    } else if (event is FetchTenderByIdEvent) {
      await _handleFetchTenderById(event);
    } else if (event is CreateTenderEvent) {
      await _handleCreateTender(event);
    } else if (event is UpdateTenderEvent) {
      await _handleUpdateTender(event);
    } else if (event is DeleteTenderEvent) {
      await _handleDeleteTender(event);
    } else if (event is ToggleFavoriteTenderEvent) {
      await _handleToggleFavoriteTender(event);
    } else if (event is FetchFavoriteTendersEvent) {
      await _handleFetchFavoriteTenders();
    } else if (event is ExtendTenderEvent) {
      await _handleExtendTender(event);
    } else if (event is CloseTenderEvent) {
      await _handleCloseTender(event);
    }
  }

  Future<void> _handleFetchTenders(FetchTendersEvent event) async {
    emitState(LoadingState());

    try {
      final tenders = await _tenderRepository.fetchTenders(
        searchQuery: event.searchQuery,
        city: event.city,
        categoryId: event.categoryId,
        userBids: event.userBids,
        unviewed: event.unviewed,
      );

      emitState(TendersLoadedState(tenders: tenders));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchUserTenders() async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();
      final tenders = await _tenderRepository.fetchUserTenders(userId);

      emitState(UserTendersLoadedState(tenders: tenders));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchTenderById(FetchTenderByIdEvent event) async {
    emitState(LoadingState());

    try {
      final tender = await _tenderRepository.fetchTenderById(event.id);
      emitState(TenderDetailsLoadedState(tender: tender));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleCreateTender(CreateTenderEvent event) async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();

      final tender = await _tenderRepository.createTender(
        userId: userId,
        title: event.title,
        city: event.city,
        budget: event.budget,
        deliveryOption: stringToDeliveryOption(event.deliveryOption),
        validWeeks: event.validWeeks,
        description: event.description,
        itemsData: event.items,
        attachments: event.attachments,
      );

      emitState(TenderCreatedState(tender: tender));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleUpdateTender(UpdateTenderEvent event) async {
    emitState(LoadingState());

    try {
      await _tenderRepository.updateTender(
        id: event.id,
        title: event.title,
        city: event.city,
        budget: event.budget,
        deliveryOption: stringToDeliveryOption(event.deliveryOption),
        validWeeks: event.validWeeks,
        description: event.description,
        itemsData: event.items,
      );

      emitState(TenderUpdatedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleDeleteTender(DeleteTenderEvent event) async {
    emitState(LoadingState());

    try {
      await _tenderRepository.deleteTender(event.id);
      emitState(TenderDeletedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleToggleFavoriteTender(ToggleFavoriteTenderEvent event) async {
    try {
      final userId = await _getCurrentUserId();
      final isFavorite = await _tenderRepository.toggleFavoriteTender(event.tenderId, userId);

      emitState(TenderFavoriteToggledState(isFavorite: isFavorite));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleFetchFavoriteTenders() async {
    emitState(LoadingState());

    try {
      final userId = await _getCurrentUserId();
      final tenders = await _tenderRepository.fetchFavoriteTenders(userId);

      emitState(FavoriteTendersLoadedState(tenders: tenders));
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleExtendTender(ExtendTenderEvent event) async {
    emitState(LoadingState());

    try {
      await _tenderRepository.extendTender(
        event.tenderId,
        event.additionalWeeks,
      );

      emitState(TenderExtendedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleCloseTender(CloseTenderEvent event) async {
    emitState(LoadingState());

    try {
      await _tenderRepository.closeTender(event.tenderId);
      emitState(TenderClosedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  // Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    // In a real app, you would get this from a user session or shared preferences
    // For now, we'll simulate it with a placeholder
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }
}