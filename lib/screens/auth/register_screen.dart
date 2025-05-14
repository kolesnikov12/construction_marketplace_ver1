import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';
import 'package:construction_marketplace/utils/responsive_builder.dart';

import '../../utils/validators.dart';
import '../../utils/responsive_builder.dart';

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
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signup(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      // Після успішної реєстрації показуємо повідомлення про необхідність підтвердження електронної пошти
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('verification_email_sent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('error')),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.translate('ok')),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('register')),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            width: isDesktop ? 700 : 400, // Much wider for desktop to fit two columns
            child: Card(
              elevation: isDesktop ? 4 : 1,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Registration heading for desktop
                      if (isDesktop) ...[
                        Icon(
                          Icons.account_circle,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          localization.translate('register'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),
                      ],

                      // Use ResponsiveRow for desktop layout with multiple columns
                      ResponsiveBuilder(
                        builder: (context, isMobile, isTablet, isDesktopView) {
                          if (isDesktopView) {
                            // Two-column layout for desktop
                            return Column(
                              children: [
                                // Name and Email in first row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildNameField(),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildEmailField(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Phone in second row
                                _buildPhoneField(),
                                SizedBox(height: 16),

                                // Password fields in third row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildPasswordField(),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildConfirmPasswordField(),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Single column layout for mobile/tablet
                            return Column(
                              children: [
                                _buildNameField(),
                                SizedBox(height: 16),
                                _buildEmailField(),
                                SizedBox(height: 16),
                                _buildPhoneField(),
                                SizedBox(height: 16),
                                _buildPasswordField(),
                                SizedBox(height: 16),
                                _buildConfirmPasswordField(),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Terms and conditions
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

                      // Register button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 12),
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
                            : Text(
                          localization.translate('register'),
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Already have account link
                      isDesktop
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(localization.translate('already_have_account_prefix')),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(localization.translate('login_now')),
                          ),
                        ],
                      )
                          : TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(localization.translate('already_have_account')),
                      ),

                      if (isDesktop)
                        SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods to build individual form fields
  Widget _buildNameField() {
    final localization = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: localization.translate('name'),
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) => Validators.validateName(value),
    );
  }

  Widget _buildEmailField() {
    final localization = AppLocalizations.of(context)!;
    return TextFormField(
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
    );
  }

  Widget _buildPhoneField() {
    final localization = AppLocalizations.of(context)!;
    return TextFormField(
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
    );
  }

  Widget _buildPasswordField() {
    final localization = AppLocalizations.of(context)!;
    return TextFormField(
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
    );
  }

  Widget _buildConfirmPasswordField() {
    final localization = AppLocalizations.of(context)!;
    return TextFormField(
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
    );
  }
}