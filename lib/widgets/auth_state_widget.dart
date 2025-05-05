import 'package:flutter/cupertino.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/bloc_provider.dart';

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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final state = snapshot.data;

        if (state is AuthenticatedState) {
          return HomeScreen();
        } else if (state is LoadingState) {
          return Scaffold(
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