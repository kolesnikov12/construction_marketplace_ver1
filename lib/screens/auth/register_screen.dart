import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

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
  bool _acceptTerms = false;  // Додаємо прийняття умов

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

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('register')),
      ),
      body: Center(
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
                    // Додаємо маску для телефонного номера через пакет mask_text_input_formatter
                    inputFormatters: [
                      // MaskTextInputFormatter(
                      //   mask: '(###) ###-####',
                      //   filter: {"#": RegExp(r'[0-9]')},
                      // ),
                    ],
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

                  // Додаємо поле для згоди з умовами
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
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(localization.translate('register')),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
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
      ),
    );
  }
}
