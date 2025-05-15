import 'package:construction_marketplace/screens/tenders/listing_list_screen.dart';
import 'package:construction_marketplace/screens/tenders/tender_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/locale_provider.dart';
import 'package:construction_marketplace/screens/tenders/create_tender_screen.dart';
import 'package:construction_marketplace/screens/listings/create_listing_screen.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

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

  void _navigateToCreateScreen() async {
    if (_tabController.index == 0) {
      // Navigate to create tender screen and wait for result
      final result = await Navigator.of(context).pushNamed(CreateTenderScreen.routeName);

      // If tender was created successfully, refresh the data
      if (result == true) {
        _refreshData();
      }
    } else {
      // Navigate to create listing screen
      final result = await Navigator.of(context).pushNamed(CreateListingScreen.routeName);

      // If listing was created successfully, refresh the data
      if (result == true) {
        _refreshData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final isEnglish = Provider.of<LocaleProvider>(context).locale.languageCode == 'en';
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('app_title')),
        centerTitle: !isLargeScreen,
        actions: [
          IconButton(
            icon: Icon(isEnglish ? Icons.language : Icons.language_outlined),
            onPressed: () {
              final provider = Provider.of<LocaleProvider>(context, listen: false);
              provider.setLocale(Locale(isEnglish ? 'fr' : 'en', ''));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localization.translate('language_changed')),
                  duration: const Duration(seconds: 1),
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
              icon: const Icon(Icons.description),
              text: localization.translate('tenders'),
            ),
            Tab(
              icon: const Icon(Icons.store),
              text: localization.translate('listings'),
            ),
          ],
        ),
      ),
      drawer: isLargeScreen ? null : AppDrawer(),
      body: Row(
        children: [
          // Side navigation for desktop
          if (isLargeScreen)
            SizedBox(
              width: 240,
              child: AppDrawer(),
            ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Search Bar - wider on desktop
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24.0 : 16.0,
                    vertical: 16.0,
                  ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_screen',
        onPressed: _navigateToCreateScreen,
        tooltip: _tabController.index == 0
            ? localization.translate('create_tender')
            : localization.translate('create_listing'),
        child: const Icon(Icons.add),
      ),
    );
  }
}