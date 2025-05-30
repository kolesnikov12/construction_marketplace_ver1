import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/screens/auth/register_screen.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    print('Submit pressed');
    try {
      if (!_formKey.currentState!.validate()) {
        print('Форма не валідна');
        return;
      }
      print('Форма валідна, надсилаю логін...');

      setState(() {
        _isLoading = true;
      });

      try {
        print('Викликаю AuthProvider.login...');
        final success = await Provider.of<AuthProvider>(context, listen: false).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        print('Логін успішний: $success');
        if (success && mounted) {
          // Перехід на головний екран
          Navigator.of(context).pushNamed(HomeScreen.routeName);
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
    } catch (e, stack) {
      print('Login error: $e');
      print(stack);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('login')),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            width: isDesktop ? 450 : 400, // Wider form on desktop
            child: Card(
              elevation: isDesktop ? 4 : 1, // Higher elevation on desktop
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32 : 16), // More padding on desktop
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Login heading and logo for desktop
                      if (isDesktop) ...[
                        Icon(
                          Icons.construction,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          localization.translate('login'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),
                      ],

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: localization.translate('email'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          hintText: 'example@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.validateEmail(value),
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      SizedBox(height: isDesktop ? 24 : 16),
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
                            // Навігація до екрану відновлення пароля
                            // Navigator.of(context).pushNamed(ForgotPasswordScreen.routeName);
                          },
                          child: Text(localization.translate('forgot_password')),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16), // Taller button on desktop
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
                          localization.translate('login'),
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14, // Larger text on desktop
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Desktop-specific layout for registration link
                      isDesktop
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(localization.translate('dont_have_account_prefix')),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(RegisterScreen.routeName);
                            },
                            child: Text(localization.translate('register_now')),
                          ),
                        ],
                      )
                          : TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(RegisterScreen.routeName);
                        },
                        child: Text(localization.translate('dont_have_account')),
                      ),

                      // Extra spacing at bottom for desktop
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
}