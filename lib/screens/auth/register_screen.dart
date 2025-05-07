// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import '../../bloc/bloc_provider.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/base/bloc_events.dart';
import '../../bloc/base/bloc_states.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('accept_terms_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Use AuthBloc instead of AuthProvider
    final authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.addEvent(AuthSignupEvent(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('register')),
      ),
      body: StreamBuilder(
        stream: authBloc.state,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is AuthenticatedState) {
              // Navigate to Home Screen on successful registration
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('verification_email_sent')),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            } else if (state is ErrorState) {
              // Show error message
              _isLoading = false;
              _errorMessage = state.message;
            } else if (state is RegisteringState) {
              _isLoading = true;
            } else if (state is EmailUnverifiedState) {
              // Handle email verification state
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('verification_email_sent')),
                    backgroundColor: Colors.green,
                  ),
                );
              });
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
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localization.translate('name'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateName(value),
                      ),
                      SizedBox(height: 16),

                      // Rest of the form fields remain the same...
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
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: localization.translate('phone'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          hintText: '(123) 456-7890',
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validatePhone(value),
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
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validatePassword(value),
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: localization.translate('confirm_password'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) => Validators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 16),

                      // Terms acceptance checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: Text(
                                localization.translate('accept_terms_and_privacy'),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                            : Text(localization.translate('register')),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(localization.translate('already_have_account')),
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