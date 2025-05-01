import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';

import '../../utils/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  web.File? _profileImage;
  Uint8List? _profileImageBytes; // Для відображення зображення
  bool _isLoading = false;
  bool _isPasswordChanging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final input = web.HTMLInputElement();
    input.type = 'file';
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0); // Отримуємо web.File
        if (file != null) {
          if (file.size > 5 * 1024 * 1024) { // Обмеження 5MB
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.translate('file_too_large')),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          final arrayBuffer = await file.arrayBuffer().toDart;
          final bytes = arrayBuffer.toDart.asUint8List();
          setState(() {
            _profileImage = file;
            _profileImageBytes = bytes; // Зберігаємо байти для відображення
          });
        }
      }
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<AuthProvider>(context, listen: false).updateProfile(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _profileImage, // Передаємо web.File?
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('profile_updated')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Unknown error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isPasswordChanging = true;
    });

    try {
      final success = await Provider.of<AuthProvider>(context, listen: false).changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('password_changed')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Unknown error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPasswordChanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localization.translate('profile')),
        ),
        body: Center(
          child: Text(localization.translate('not_logged_in')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('profile')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localization.translate('profile_info')),
            Tab(text: localization.translate('change_password')),
          ],
        ),
      ),
      drawer: AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Info Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!) as ImageProvider
                          : (user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!) as ImageProvider
                          : null),
                      child: _profileImageBytes == null && user.profileImageUrl == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_camera),
                  label: Text(localization.translate('change_photo')),
                ),
                SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localization.translate('name'),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: localization.translate('email'),
                          border: OutlineInputBorder(),
                        ),
                        enabled: false,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: localization.translate('phone'),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(localization.translate('update_profile')),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Change Password Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: localization.translate('current_password'),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localization.translate('field_required');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: localization.translate('new_password'),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localization.translate('field_required');
                      }
                      if (value.length < 6) {
                        return localization.translate('password_short');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: localization.translate('confirm_password'),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localization.translate('field_required');
                      }
                      if (value != _newPasswordController.text) {
                        return localization.translate('passwords_dont_match');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isPasswordChanging ? null : _changePassword,
                    child: _isPasswordChanging
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(localization.translate('change_password')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}