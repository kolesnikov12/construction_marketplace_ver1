import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/screens/home_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:construction_marketplace/screens/tenders/my_tenders_screen.dart';
import 'package:construction_marketplace/screens/listings/my_listings_screen.dart';
import 'package:construction_marketplace/screens/profile/profile_screen.dart';
import 'package:construction_marketplace/screens/favorites/favorites_screen.dart';
import 'package:construction_marketplace/screens/auth/login_screen.dart';
import 'package:construction_marketplace/screens/auth/register_screen.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';

import '../screens/tenders/listing_list_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    // For desktop screens, we modify the drawer to be a permanent sidebar
    // but the content remains the same
    return isLargeScreen
        ? AppDrawerContent(isPermanent: true)
        : Drawer(
      child: AppDrawerContent(isPermanent: false),
    );
  }
}

class AppDrawerContent extends StatelessWidget {
  final bool isPermanent;

  const AppDrawerContent({
    Key? key,
    this.isPermanent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    // Helper method to close drawer if not permanent
    void _navigateTo(BuildContext context, String routeName) {
      if (!isPermanent) {
        Navigator.of(context).pop();
      }
      Navigator.of(context).pushReplacementNamed(routeName);
    }

    return Container(
      color: isPermanent ? Theme.of(context).scaffoldBackgroundColor : null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? localization.translate('guest')),
            accountEmail: Text(user?.email ?? localization.translate('not_logged_in')),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? Icon(Icons.person, size: isLargeScreen ? 48 : 40)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text(localization.translate('home')),
            onTap: () => _navigateTo(context, HomeScreen.routeName),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.description),
            title: Text(localization.translate('all_tenders')),
            onTap: () => _navigateTo(context, TenderListScreen.routeName),
          ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text(localization.translate('all_listings')),
            onTap: () => _navigateTo(context, ListingListScreen.routeName),
          ),
          if (authProvider.isAuth) ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text(localization.translate('profile')),
              onTap: () => _navigateTo(context, ProfileScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text(localization.translate('favorites')),
              onTap: () => _navigateTo(context, FavoritesScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text(localization.translate('my_tenders')),
              onTap: () => _navigateTo(context, MyTendersScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text(localization.translate('my_listings')),
              onTap: () => _navigateTo(context, MyListingsScreen.routeName),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text(localization.translate('logout')),
              onTap: () {
                if (!isPermanent) {
                  Navigator.of(context).pop();
                }
                authProvider.logout();
                // After logout, navigate to login screen
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              },
            ),
          ] else ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.login),
              title: Text(localization.translate('login')),
              onTap: () => _navigateTo(context, LoginScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text(localization.translate('register')),
              onTap: () => _navigateTo(context, RegisterScreen.routeName),
            ),
          ],
          // Additional footer for desktop view
          if (isPermanent) ...[
            const SizedBox(height: 24),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '© 2025 Construction Marketplace',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}