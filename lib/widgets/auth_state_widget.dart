import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/base/bloc_states.dart';
import '../bloc/bloc_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

class AuthStateWidget extends StatefulWidget {
  @override
  _AuthStateWidgetState createState() => _AuthStateWidgetState();
}

class _AuthStateWidgetState extends State<AuthStateWidget> {
  @override
  void initState() {
    super.initState();
    // Check authentication status when app starts
    Future.microtask(() {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      authBloc.checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return StreamBuilder(
      stream: authBloc.state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final state = snapshot.data;

        if (state is AuthenticatedState) {
          return HomeScreen();
        } else if (state is LoadingState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}