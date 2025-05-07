import '../repositorties/auth_repository.dart';
import 'base/bloc_base.dart';
import 'base/bloc_events.dart';
import 'base/bloc_states.dart';
import 'package:web/web.dart' as web;

class AuthBloc extends Bloc {
  final AuthRepository _authRepository = AuthRepository();

  // 2. Fix for auth_bloc.dart to implement the _handleEvent method:

  // In auth_bloc.dart:
  void handleEvent(BlocEvent event) async {
    if (event is AuthLoginEvent) {
      await _handleLogin(event);
    } else if (event is AuthSignupEvent) {
      await _handleSignup(event);
    } else if (event is AuthLogoutEvent) {
      await _handleLogout();
    } else if (event is AuthUpdateProfileEvent) {
      await _handleUpdateProfile(event);
    }
  }

  Future<void> _handleLogin(AuthLoginEvent event) async {
    emitState(AuthenticatingState());

    try {
      final result = await _authRepository.login(event.email, event.password);

      if (result['success']) {
        emitState(AuthenticatedState(
          user: result['user'],
          token: result['token'],
        ));
      } else {
        emitState(ErrorState(message: result['error']));
      }
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleSignup(AuthSignupEvent event) async {
    emitState(RegisteringState());

    try {
      final result = await _authRepository.signup(
        event.email,
        event.password,
        event.name,
        event.phone,
      );

      if (result['success']) {
        if (result['user'].isEmailVerified) {
          emitState(AuthenticatedState(
            user: result['user'],
            token: result['token'],
          ));
        } else {
          emitState(EmailUnverifiedState());
        }
      } else {
        emitState(ErrorState(message: result['error']));
      }
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authRepository.logout();
      emitState(UnauthenticatedState());
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> _handleUpdateProfile(AuthUpdateProfileEvent event) async {
    emitState(LoadingState());

    try {
      final result = await _authRepository.updateProfile(
        event.userId,
        event.name,
        event.phone,
        event.profileImage,
      );

      if (result['success']) {
        emitState(ProfileUpdatedState(user: result['user']));
      } else {
        emitState(ErrorState(message: result['error']));
      }
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }

  Future<void> checkAuthStatus() async {
    emitState(LoadingState());

    try {
      final result = await _authRepository.checkAuth();

      if (result['success']) {
        emitState(AuthenticatedState(
          user: result['user'],
          token: result['token'],
        ));
      } else {
        emitState(UnauthenticatedState());
      }
    } catch (e) {
      emitState(ErrorState(message: e.toString()));
    }
  }
}