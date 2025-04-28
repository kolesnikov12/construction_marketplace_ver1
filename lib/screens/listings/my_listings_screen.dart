import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/screens/listings/listing_detail_screen.dart';
import 'package:construction_marketplace/screens/listings/create_listing_screen.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/widgets/listings/listing_grid_item.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

import '../../models/basic_models.dart';

class MyListingsScreen extends StatefulWidget {
  static const routeName = '/listings/my';

  @override
  _MyListingsScreenState createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ListingProvider>(context, listen: false).fetchUserListings();
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

  Future<void> _markListingAsSold(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('mark_as_sold')),
        content: Text(AppLocalizations.of(context)!.translate('mark_as_sold_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.translate('mark_as_sold')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ListingProvider>(context, listen: false).markListingAsSold(listingId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('listing_marked_as_sold')),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('delete_listing')),
        content: Text(AppLocalizations.of(context)!.translate('delete_listing_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ListingProvider>(context, listen: false).deleteListing(listingId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('listing_deleted')),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildListingGrid(List<Listing> listings, ListingStatus status) {
    final filteredListings = listings.where((listing) => listing.status == status).toList();

    if (filteredListings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('no_listings_found'),
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredListings.length,
      itemBuilder: (ctx, index) {
        final listing = filteredListings[index];
        return ListingGridItem(
          listing: listing,
          onTap: () {
            Navigator.of(context).pushNamed(
              ListingDetailScreen.routeName,
              arguments: listing.id,
            );
          },
          actionBuilder: (BuildContext context) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (listing.status == ListingStatus.available)
                  IconButton(
                    icon: Icon(Icons.check_circle_outline),
                    tooltip: AppLocalizations.of(context)!.translate('mark_as_sold'),
                    onPressed: () => _markListingAsSold(listing.id),
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () => _deleteListing(listing.id),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final listingProvider = Provider.of<ListingProvider>(context);
    final userListings = listingProvider.userListings;

    return Scaffold(
        appBar: AppBar(
        title: Text(localization.translate('my_listings')),
    bottom: TabBar(
    controller: _tabController,
    tabs: [
    Tab(text: localization.translate('available')),
    Tab(text: localization.translate('sold')),
    Tab(text: localization.translate('expired')),
    ],
    ),
    ),
    drawer: AppDrawer(),
    body: _isLoading
    ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
    onRefresh: _loadUserListings,
    child: TabBarView(
    controller: _tabController,
    children: [
    _buildListingGrid(userListings, ListingStatus.available),
    _buildListingGrid(userListings, ListingStatus.sold),
    _buildListingGrid(userListings, ListingStatus.expired),
    ],
    ),
    ),
    floatingActionButton: FloatingActionButton(
    onPressed: () {
    Navigator.of(context).pushNamed(CreateListingScreen.routeName);
    },
    child: Icon(Icons.add),
    tooltip: localization.translate('create_listing'),
    ),