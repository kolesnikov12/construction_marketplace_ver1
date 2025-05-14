import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';

import 'package:construction_marketplace/screens/tenders/tender_detail_screen.dart';
import 'package:construction_marketplace/widgets/tenders/tender_list_item.dart';
import 'package:construction_marketplace/widgets/tenders/filter_dialog.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';

class TenderListScreen extends StatefulWidget {
  static const routeName = '/tenders';
  final String searchQuery;

  const TenderListScreen({
    Key? key,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  _TenderListScreenState createState() => _TenderListScreenState();
}

class _TenderListScreenState extends State<TenderListScreen> {
  String? _selectedCity;
  String? _selectedCategoryId;
  bool _showUserBids = false;
  bool _showUnviewed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  @override
  void didUpdateWidget(TenderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _loadTenders();
    }
  }

  Future<void> _loadTenders() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<TenderProvider>(context, listen: false).fetchTenders(
      searchQuery: widget.searchQuery,
      city: _selectedCity,
      categoryId: _selectedCategoryId,
      userBids: _showUserBids,
      unviewed: _showUnviewed,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => FilterDialog(
        initialCity: _selectedCity,
        initialCategoryId: _selectedCategoryId,
        showUserBids: _showUserBids,
        showUnviewed: _showUnviewed,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCity = result['city'];
        _selectedCategoryId = result['categoryId'];
        _showUserBids = result['showUserBids'];
        _showUnviewed = result['showUnviewed'];
      });

      _loadTenders();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategoryId = null;
      _showUserBids = false;
      _showUnviewed = false;
    });

    _loadTenders();
  }

  bool get _hasActiveFilters {
    return _selectedCity != null ||
        _selectedCategoryId != null ||
        _showUserBids ||
        _showUnviewed;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderProvider = Provider.of<TenderProvider>(context);
    final tenders = tenderProvider.tenders;
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final contentPadding = ResponsiveHelper.getContentPadding(context);

    return Scaffold(
      appBar: widget.searchQuery.isEmpty ? AppBar(
        automaticallyImplyLeading: false,
        title: Text(localization.translate('tenders')),
      ) : null,
      body: Column(
        children: [
          if (_hasActiveFilters)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24.0 : 16.0,
                  vertical: 8.0
              ),
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
                                  _loadTenders();
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
                                      _loadTenders();
                                    },
                                  );
                                },
                              ),
                            ),
                          if (_showUserBids)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(localization.translate('tenders_with_my_bids')),
                                onDeleted: () {
                                  setState(() {
                                    _showUserBids = false;
                                  });
                                  _loadTenders();
                                },
                              ),
                            ),
                          if (_showUnviewed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(localization.translate('unviewed_tenders')),
                                onDeleted: () {
                                  setState(() {
                                    _showUnviewed = false;
                                  });
                                  _loadTenders();
                                },
                              ),
                            ),
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
              onRefresh: _loadTenders,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : tenders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      localization.translate('no_tenders_found'),
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
                  : Padding(
                padding: contentPadding,
                child: isLargeScreen
                // Desktop view - use a more efficient layout
                    ? ListView.builder(
                  itemCount: tenders.length,
                  itemBuilder: (ctx, index) {
                    final tender = tenders[index];
                    return TenderListItem(
                      tender: tender,
                      isDesktopView: true,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          TenderDetailScreen.routeName,
                          arguments: tender.id,
                        );
                      },
                    );
                  },
                )
                // Mobile view - standard list
                    : ListView.builder(
                  itemCount: tenders.length,
                  itemBuilder: (ctx, index) {
                    final tender = tenders[index];
                    return TenderListItem(
                      tender: tender,
                      isDesktopView: false,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          TenderDetailScreen.routeName,
                          arguments: tender.id,
                        );
                      },
                    );
                  },
                ),
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