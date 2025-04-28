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

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
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
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text(localization.translate('home')),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.description),
            title: Text(localization.translate('all_tenders')),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(TenderListScreen.routeName);
            },
          ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text(localization.translate('all_listings')),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(ListingListScreen.routeName);
            },
          ),
          if (authProvider.isAuth) ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text(localization.translate('profile')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(ProfileScreen.routeName);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text(localization.translate('favorites')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(FavoritesScreen.routeName);
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text(localization.translate('my_tenders')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(MyTendersScreen.routeName);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text(localization.translate('my_listings')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(MyListingsScreen.routeName);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text(localization.translate('logout')),
              onTap: () {
                Navigator.of(context).pop();
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
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(LoginScreen.routeName);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text(localization.translate('register')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(RegisterScreen.routeName);
              },
            ),
          ],
        ],
      ),
    );
  }
}