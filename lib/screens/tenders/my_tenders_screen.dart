import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/screens/tenders/tender_detail_screen.dart';
import 'package:construction_marketplace/screens/tenders/create_tender_screen.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/widgets/tenders/tender_list_item.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';
import 'package:construction_marketplace/utils/responsive_builder.dart';
import '../../models/enums.dart';
import '../../models/tender.dart';

class MyTendersScreen extends StatefulWidget {
  static const routeName = '/tenders/my';

  @override
  _MyTendersScreenState createState() => _MyTendersScreenState();
}

class _MyTendersScreenState extends State<MyTendersScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserTenders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTenders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<TenderProvider>(context, listen: false).fetchUserTenders();
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

  Future<void> _extendTender(String tenderId) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('extend_tender')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('extend_tender_duration')),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4].map((weeks) {
                  return ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();

                      try {
                        await Provider.of<TenderProvider>(context, listen: false)
                            .extendTender(tenderId, weeks);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.translate('tender_extended')),
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
                    },
                    child: Text('$weeks ${AppLocalizations.of(context)!.translate(weeks == 1 ? 'week' : 'weeks')}'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _closeTender(String tenderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('close_tender')),
        content: Text(AppLocalizations.of(context)!.translate('close_tender_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.translate('close')),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<TenderProvider>(context, listen: false).closeTender(tenderId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('tender_closed')),
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

  Future<void> _deleteTender(String tenderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('delete_tender')),
        content: Text(AppLocalizations.of(context)!.translate('delete_tender_confirm')),
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
        await Provider.of<TenderProvider>(context, listen: false).deleteTender(tenderId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('tender_deleted')),
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

  Widget _buildTenderList(List<Tender> tenders, TenderStatus status, bool isMobile, bool isTablet) {
    final localization = AppLocalizations.of(context)!;
    final filteredTenders = tenders.where((tender) => tender.status == status).toList();

    if (filteredTenders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('no_tenders_found'),
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return ResponsiveRow(
      spacing: 16,
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      children: filteredTenders.map((tender) {
        return Card(
          margin: EdgeInsets.zero,
          child: TenderListItem(
            tender: tender,
            onTap: () {
              Navigator.of(context).pushNamed(
                TenderDetailScreen.routeName,
                arguments: tender.id,
              );
            },
            trailingBuilder: (BuildContext context) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'extend':
                      await _extendTender(tender.id);
                      break;
                    case 'close':
                      await _closeTender(tender.id);
                      break;
                    case 'delete':
                      await _deleteTender(tender.id);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  if (tender.status != TenderStatus.closed)
                    PopupMenuItem(
                      value: 'extend',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text(localization.translate('extend')),
                        ],
                      ),
                    ),
                  if (tender.status != TenderStatus.closed)
                    PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text(localization.translate('mark_as_closed')),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          localization.translate('delete'),
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderProvider = Provider.of<TenderProvider>(context);
    final userTenders = tenderProvider.userTenders;

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('my_tenders')),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: localization.translate('open')),
                Tab(text: localization.translate('extended')),
                Tab(text: localization.translate('closed')),
              ],
            ),
          ),
          drawer: isMobile ? AppDrawer() : null,
          body: Row(
            children: [
              // Show drawer as sidebar on tablet and desktop
              if (!isMobile)
                SizedBox(
                  width: 250,
                  child: AppDrawer(),
                ),

              // Main content
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: _loadUserTenders,
                  child: Padding(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getScreenPadding(context).left,
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveHelper.getContentMaxWidth(context),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTenderList(userTenders, TenderStatus.open, isMobile, isTablet),
                          _buildTenderList(userTenders, TenderStatus.extended, isMobile, isTablet),
                          _buildTenderList(userTenders, TenderStatus.closed, isMobile, isTablet),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(CreateTenderScreen.routeName);
            },
            child: Icon(Icons.add),
            tooltip: localization.translate('create_tender'),
          ),
        );
      },
    );
  }
}