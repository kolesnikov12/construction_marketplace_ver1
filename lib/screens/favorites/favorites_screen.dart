import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/screens/tenders/tender_detail_screen.dart';
import 'package:construction_marketplace/screens/listings/listing_detail_screen.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/widgets/tenders/tender_list_item.dart';
import 'package:construction_marketplace/widgets/listings/listing_grid_item.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';
import 'package:construction_marketplace/utils/responsive_builder.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tenderProvider = Provider.of<TenderProvider>(context, listen: false);
      final listingProvider = Provider.of<ListingProvider>(context, listen: false);

      await Future.wait([
        tenderProvider.fetchFavoriteTenders(),
        listingProvider.fetchFavoriteListings(),
      ]);
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('error')),
          content: Text(error.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.translate('ok')),
            )
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

  Future<void> _toggleFavoriteTender(String tenderId) async {
    try {
      await Provider.of<TenderProvider>(context, listen: false).toggleFavoriteTender(tenderId);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFavoriteListing(String listingId) async {
    try {
      await Provider.of<ListingProvider>(context, listen: false).toggleFavoriteListing(listingId);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderProvider = Provider.of<TenderProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);

    final favoriteTenders = tenderProvider.favoriteTenders;
    final favoriteListings = listingProvider.favoriteListings;

    // Use ResponsiveBuilder to adapt the layout based on screen size
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('favorites')),
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
          drawer: isMobile ? AppDrawer() : null,
          body: Row(
            children: [
              // Show sidebar on tablet and desktop
              if (!isMobile)
                SizedBox(
                  width: 250,
                  child: AppDrawer(),
                ),

              // Main content area
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: Padding(
                    padding: EdgeInsets.all(
                        ResponsiveHelper.getScreenPadding(context).left
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Favorite Tenders Tab
                        favoriteTenders.isEmpty
                            ? Center(
                          child: Text(localization.translate('no_favorites')),
                        )
                            : ListView.builder(
                          itemCount: favoriteTenders.length,
                          itemBuilder: (ctx, index) {
                            final tender = favoriteTenders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TenderListItem(
                                tender: tender,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    TenderDetailScreen.routeName,
                                    arguments: tender.id,
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // Favorite Listings Tab
                        favoriteListings.isEmpty
                            ? Center(
                          child: Text(localization.translate('no_favorites')),
                        )
                            : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                            isMobile ? 2 : (isTablet ? 3 : 4),
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: favoriteListings.length,
                          itemBuilder: (ctx, index) {
                            final listing = favoriteListings[index];
                            return ListingGridItem(
                              listing: listing,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  ListingDetailScreen.routeName,
                                  arguments: listing.id,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}