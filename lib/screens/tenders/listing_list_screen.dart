import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/screens/listings/listing_detail_screen.dart';
import 'package:construction_marketplace/widgets/listings/listing_grid_item.dart';
import 'package:construction_marketplace/widgets/listings/listing_filter_dialog.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

class ListingListScreen extends StatefulWidget {
  static const routeName = '/listings';
  final String searchQuery;

  const ListingListScreen({
    Key? key,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  _ListingListScreenState createState() => _ListingListScreenState();
}

class _ListingListScreenState extends State<ListingListScreen> {
  String? _selectedCity;
  String? _selectedCategoryId;
  bool _showUnviewed = false;
  List<String> _selectedDeliveryOptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void didUpdateWidget(ListingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _loadListings();
    }
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ListingProvider>(context, listen: false).fetchListings(
        searchQuery: widget.searchQuery,
        city: _selectedCity,
        categoryId: _selectedCategoryId,
        unviewed: _showUnviewed,
        deliveryOptions: _selectedDeliveryOptions.isNotEmpty
            ? _selectedDeliveryOptions
            : null,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
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

  void _openFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ListingFilterDialog(
        initialCity: _selectedCity,
        initialCategoryId: _selectedCategoryId,
        showUnviewed: _showUnviewed,
        selectedDeliveryOptions: _selectedDeliveryOptions,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCity = result['city'];
        _selectedCategoryId = result['categoryId'];
        _showUnviewed = result['showUnviewed'];
        _selectedDeliveryOptions = result['deliveryOptions'];
      });

      _loadListings();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategoryId = null;
      _showUnviewed = false;
      _selectedDeliveryOptions = [];
    });

    _loadListings();
  }

  bool get _hasActiveFilters {
    return _selectedCity != null ||
        _selectedCategoryId != null ||
        _showUnviewed ||
        _selectedDeliveryOptions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final listingProvider = Provider.of<ListingProvider>(context);
    final listings = listingProvider.listings;

    return Scaffold(
      appBar: widget.searchQuery.isEmpty ? AppBar(
        automaticallyImplyLeading: false, // Add this line
        title: Text(localization.translate('listings')),
      ) : null,
      body: Column(
        children: [
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCity != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_selectedCity!),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCity = null;
                                  });
                                  _loadListings();
                                },
                              ),
                            ),
                          if (_selectedCategoryId != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Consumer<CategoryProvider>(
                                builder: (ctx, categoryProvider, _) {
                                  final category = categoryProvider.getCategoryById(_selectedCategoryId!);
                                  final categoryName = category != null
                                      ? (localization.isEnglish() ? category.nameEn : category.nameFr)
                                      : _selectedCategoryId!;

                                  return Chip(
                                    label: Text(categoryName),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                      _loadListings();
                                    },
                                  );
                                },
                              ),
                            ),
                          if (_showUnviewed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(localization.translate('unviewed_listings')),
                                onDeleted: () {
                                  setState(() {
                                    _showUnviewed = false;
                                  });
                                  _loadListings();
                                },
                              ),
                            ),
                          ..._selectedDeliveryOptions.map((option) {
                            String label;
                            switch (option) {
                              case 'pickup':
                                label = localization.translate('pickup_only');
                                break;
                              case 'delivery':
                                label = localization.translate('can_ship');
                                break;
                              case 'discuss':
                                label = localization.translate('requires_discussion');
                                break;
                              default:
                                label = option;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(label),
                                onDeleted: () {
                                  setState(() {
                                    _selectedDeliveryOptions.remove(option);
                                  });
                                  _loadListings();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear_all),
                    onPressed: _clearFilters,
                    tooltip: localization.translate('clear_filters'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadListings,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : listings.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      localization.translate('no_listings_found'),
                      style: TextStyle(fontSize: 18),
                    ),
                    if (_hasActiveFilters) ...[
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _clearFilters,
                        child: Text(localization.translate('clear_filters')),
                      ),
                    ],
                  ],
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: listings.length,
                itemBuilder: (ctx, index) {
                  final listing = listings[index];
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilterDialog,
        child: Icon(Icons.filter_list),
        tooltip: localization.translate('filter'),
      ),
    );
  }
}