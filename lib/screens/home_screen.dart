// lib/screens/home_screen.dart
import 'package:construction_marketplace/screens/tenders/listing_list_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/locale_provider.dart';
import 'package:construction_marketplace/screens/tenders/create_tender_screen.dart';
import 'package:construction_marketplace/screens/listings/create_listing_screen.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

import '../widgets/app_drawer.dart';

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

