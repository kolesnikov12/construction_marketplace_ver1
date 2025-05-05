
import 'package:flutter/material.dart';
import '../../bloc/bloc_provider.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/base/bloc_events.dart';
import '../../bloc/base/bloc_states.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.addEvent(AuthLoginEvent(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('login')),
      ),
      body: StreamBuilder(
        stream: authBloc.state,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is AuthenticatedState) {
              // Navigate to Home Screen on successful login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context)
                    .pushReplacementNamed(HomeScreen.routeName);
              });
            } else if (state is ErrorState) {
              // Show error message
              _isLoading = false;
              _errorMessage = state.message;
            } else if (state is AuthenticatingState) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }
          }

          return Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16),
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: localization.translate('email'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          hintText: 'example@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateEmail(value),
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: localization.translate('password'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('field_required');
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Navigation to reset password screen
                            // Navigator.of(context).pushNamed(ForgotPasswordScreen.routeName);
                          },
                          child:
                              Text(localization.translate('forgot_password')),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(localization.translate('login')),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(RegisterScreen.routeName);
                        },
                        child:
                            Text(localization.translate('dont_have_account')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
