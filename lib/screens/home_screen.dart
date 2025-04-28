// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/locale_provider.dart';
import 'package:construction_marketplace/screens/tenders/create_tender_screen.dart';
import 'package:construction_marketplace/screens/listings/create_listing_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:construction_marketplace/screens/listings/listing_list_screen.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tenderProvider = Provider.of<TenderProvider>(context, listen: false);
      final listingProvider = Provider.of<ListingProvider>(context, listen: false);

      // Update the token and userId in providers
      tenderProvider.update(authProvider.token, authProvider.user?.id);
      listingProvider.update(authProvider.token, authProvider.user?.id);

      // Fetch initial data
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // Reset search when changing tabs
    if (_tabController.indexIsChanging) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  Future<void> _refreshData() async {
    final tenderProvider = Provider.of<TenderProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(context, listen: false);

    await tenderProvider.fetchTenders();
    await listingProvider.fetchListings();

    if (mounted) {
      setState(() {});
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (_tabController.index == 0) {
      // Search in tenders
      Provider.of<TenderProvider>(context, listen: false).fetchTenders(
        searchQuery: query,
      );
    } else {
      // Search in listings
      Provider.of<ListingProvider>(context, listen: false).fetchListings(
        searchQuery: query,
      );
    }
  }

  void _navigateToCreateScreen() {
    if (_tabController.index == 0) {
      // Navigate to create tender screen
      Navigator.of(context).pushNamed(CreateTenderScreen.routeName);
    } else {
      // Navigate to create listing screen
      Navigator.of(context).pushNamed(CreateListingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final isEnglish = Provider.of<LocaleProvider>(context).locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('app_title')),
        actions: [
          IconButton(
            icon: Icon(isEnglish ? Icons.language : Icons.language_outlined),
            onPressed: () {
              final provider = Provider.of<LocaleProvider>(context, listen: false);
              provider.setLocale(Locale(isEnglish ? 'fr' : 'en', ''));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localization.translate('language_changed')),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: isEnglish ? 'Switch to French' : 'Switch to English',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.description),
              text: localization.translate('tenders'),
            ),
            Tab(
              icon: Icon(Icons.store),
              text: localization.translate('listings'),
            ),
          ],
        ),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localization.translate('search'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
                    : null,
              ),
              onChanged: _performSearch,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tenders Tab
                RefreshIndicator(
                  onRefresh: () => Provider.of<TenderProvider>(context, listen: false).fetchTenders(
                    searchQuery: _searchQuery,
                  ),
                  child: TenderListScreen(searchQuery: _searchQuery),
                ),

                // Listings Tab
                RefreshIndicator(
                  onRefresh: () => Provider.of<ListingProvider>(context, listen: false).fetchListings(
                    searchQuery: _searchQuery,
                  ),
                  child: ListingListScreen(searchQuery: _searchQuery),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateScreen,
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0
            ? localization.translate('create_tender')
            : localization.translate('create_listing'),
      ),
    );
  }
}

// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/screens/home_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:construction_marketplace/screens/listings/listing_list_screen.dart';
import 'package:construction_marketplace/screens/tenders/my_tenders_screen.dart';
import 'package:construction_marketplace/screens/listings/my_listings_screen.dart';
import 'package:construction_marketplace/screens/profile/profile_screen.dart';
import 'package:construction_marketplace/screens/favorites/favorites_screen.dart';
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
            accountName: Text(user?.name ?? ''),
            accountEmail: Text(user?.email ?? ''),
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
              },
            ),
          ] else ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.login),
              title: Text(localization.translate('login')),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to login screen
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text(localization.translate('register')),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to register screen
              },
            ),
          ],
        ],
      ),
    );
  }
}