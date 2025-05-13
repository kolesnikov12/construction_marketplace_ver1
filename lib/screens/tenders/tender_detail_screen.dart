import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/enums.dart';
import '../../models/tender.dart';

class TenderDetailScreen extends StatefulWidget {
  static const routeName = '/tenders/detail';

  @override
  _TenderDetailScreenState createState() => _TenderDetailScreenState();
}

class _TenderDetailScreenState extends State<TenderDetailScreen> {
  bool _isLoading = true;
  Tender? _tender;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTender();
  }

  Future<void> _loadTender() async {
    setState(() {
      _isLoading = true;
    });

    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments == null || arguments is! String) {
      _logDebug('Error: tenderId is null or not a String');
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('error')),
          content: Text('Tender ID is missing'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.translate('ok')),
            )
          ],
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final tenderId = arguments;

    try {
      final tender = await Provider.of<TenderProvider>(context, listen: false)
          .fetchTenderById(tenderId);

      setState(() {
        _tender = tender;
        _isLoading = false;
      });
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

      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_tender == null) return;

    try {
      await Provider.of<TenderProvider>(context, listen: false)
          .toggleFavoriteTender(_tender!.id);

      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bidOnTender() async {
    if (_tender == null) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(AppLocalizations.of(context)!.translate('login_to_bid')),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.translate('login'),
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
        Text(AppLocalizations.of(context)!.translate('bid_on_tender')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!
                .translate('bid_on_tender_confirm')),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText:
                AppLocalizations.of(context)!.translate('bid_amount'),
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText:
                AppLocalizations.of(context)!.translate('bid_message'),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .translate('bid_submitted')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
                AppLocalizations.of(context)!.translate('submit_bid')),
          ),
        ],
      ),
    );
  }

  void _logDebug(String message) {
    developer.log(message, name: 'TenderDetailScreen');
    print('TenderDetailScreen: $message');
  }

  // Check server response and content type
  Future<bool> _checkImageUrl(String url) async {
    try {
      final processedUrl = url.contains('?alt=media')
          ? url
          : '${url.split('?')[0]}?alt=media';
      final response = await http.get(Uri.parse(processedUrl));
      _logDebug('HTTP response for $processedUrl: ${response.statusCode}');
      _logDebug('Headers: ${response.headers}');
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        _logDebug('Content-Type: $contentType');
        return contentType?.startsWith('image/') ?? false;
      }
      _logDebug('Failed with status: ${response.statusCode}');
      return false;
    } catch (e, stackTrace) {
      _logDebug('Error checking image URL: $e');
      _logDebug('Stack trace: $stackTrace');
      return false;
    }
  }

  Widget _buildAttachmentsList() {
    _logDebug('attachmentUrls: ${_tender?.attachmentUrls}');
    if (_tender?.attachmentUrls == null || _tender!.attachmentUrls!.isEmpty) {
      _logDebug('No attachments available');
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          AppLocalizations.of(context)!.translate('no_attachments'),
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('attachments'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        Container(
          height: 220,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _tender!.attachmentUrls!.length > 10 ? 10 : _tender!.attachmentUrls!.length,
            itemBuilder: (ctx, index) {
              final url = _tender!.attachmentUrls![index];
              // Додаємо ?alt=media, якщо його немає
              final processedUrl = url.contains('?alt=media')
                  ? url
                  : '${url.split('?')[0]}?alt=media';
              _logDebug('Processing image URL: $processedUrl');

              return FutureBuilder<bool>(
                future: _checkImageUrl(processedUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final isValidImage = snapshot.data ?? false;
                  final error = snapshot.error;

                  return GestureDetector(
                    onTap: () => _openAttachment(processedUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isValidImage
                          ? Image.network(
                        processedUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            _logDebug('Image loaded successfully');
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          _logDebug('Error loading image: $error');
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 36, color: Colors.red),
                                SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.translate('could_not_load_image'),
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 36, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.translate('could_not_load_image'),
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachment(String url) async {
    final localization = AppLocalizations.of(context)!;
    _logDebug('Opening attachment: $url');

    // Use original URL
    String cleanUrl = url;

    // Check if URL is valid before opening
    final isValidImage = await _checkImageUrl(cleanUrl);
    if (!isValidImage) {
      _logDebug('Invalid image URL, attempting to open in browser');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('could_not_load_image')),
        ),
      );
      try {
        final Uri uri = Uri.parse(cleanUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _logDebug('Cannot launch URL');
        }
      } catch (e) {
        _logDebug('Error launching URL: $e');
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(15),
        backgroundColor: Colors.transparent,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.download),
                  tooltip: localization.translate('download_image'),
                  onPressed: () async {
                    try {
                      _logDebug('Attempting to launch for download: $cleanUrl');
                      final Uri uri = Uri.parse(cleanUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        _logDebug('Cannot launch URL');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(localization
                                  .translate('cannot_open_url'))),
                        );
                      }
                    } catch (e) {
                      _logDebug('Error launching URL: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    cleanUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        _logDebug('Fullscreen image loaded successfully');
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      _logDebug('Error loading fullscreen image: $error');
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            localization.translate('could_not_load_image'),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final Uri uri = Uri.parse(cleanUrl);
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                _logDebug('Error opening in browser: $e');
                              }
                            },
                            child:
                            Text(localization.translate('open_in_browser')),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderProvider = Provider.of<TenderProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final isFavorite =
        _tender != null && tenderProvider.favoriteTenders.any((item) => item.id == _tender!.id);

    final isCreator = _tender != null &&
        authProvider.user != null &&
        _tender!.userId == authProvider.user!.id;

    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('MMMM d, yyyy');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localization.translate('tender_details')),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tender == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localization.translate('tender_details')),
        ),
        body: Center(
          child: Text(localization.translate('tender_not_found')),
        ),
      );
    }

    String statusMessage;
    Color statusColor;

    switch (_tender!.status) {
      case TenderStatus.open:
        if (_tender!.validUntil.isAfter(DateTime.now())) {
          statusMessage = localization.translate('open');
          statusColor = Colors.green;
        } else {
          statusMessage = localization.translate('expired');
          statusColor = Colors.orange;
        }
        break;
      case TenderStatus.extended:
        if (_tender!.validUntil.isAfter(DateTime.now())) {
          statusMessage = localization.translate('extended');
          statusColor = Colors.blue;
        } else {
          statusMessage = localization.translate('expired');
          statusColor = Colors.orange;
        }
        break;
      case TenderStatus.closed:
        statusMessage = localization.translate('closed');
        statusColor = Colors.grey;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(localization.translate('tender_details')),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite
                ? localization.translate('remove_from_favorites')
                : localization.translate('add_to_favorites'),
          ),
        ],
      ),

      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tender!.status == TenderStatus.open ||
                        _tender!.status == TenderStatus.extended
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: statusColor,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    statusMessage,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_tender!.status != TenderStatus.closed) ...[
                    Text(
                      ' • ${localization.translate('valid_until')} ${dateFormatter.format(_tender!.validUntil)}',
                      style: TextStyle(
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tender!.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money,
                            color: Colors.blue[800], size: 20),
                        SizedBox(width: 4),
                        Text(
                          '${localization.translate('budget')}: ${formatter.format(_tender!.budget)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tender!.city,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _tender!.deliveryOption ==
                                  DeliveryOption.pickup
                                  ? Icons.store
                                  : (_tender!.deliveryOption ==
                                  DeliveryOption.delivery
                                  ? Icons.local_shipping
                                  : Icons.question_answer),
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tender!.deliveryOption ==
                                    DeliveryOption.pickup
                                    ? localization
                                    .translate('pickup_only')
                                    : (_tender!.deliveryOption ==
                                    DeliveryOption.delivery
                                    ? localization
                                    .translate('delivery_required')
                                    : localization.translate(
                                    'requires_discussion')),
                                style:
                                TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_tender!.description != null &&
                      _tender!.description!.isNotEmpty) ...[
                    Text(
                      localization.translate('description'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _tender!.description!,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                  ],
                  _buildAttachmentsList(),
                  SizedBox(height: 24),
                  Text(
                    localization.translate('items'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _tender!.items.length,
                    itemBuilder: (ctx, index) {
                      final item = _tender!.items[index];
                      final categoryName = categoryProvider.getCategoryName(
                        item.categoryId,
                        localization.isEnglish(),
                      );
                      String? subcategoryName;
                      subcategoryName = categoryProvider.getCategoryName(
                        item.subcategoryId,
                        localization.isEnglish(),
                      );

                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.category,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    subcategoryName != null
                                        ? '$categoryName > $subcategoryName'
                                        : categoryName,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.format_list_numbered,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    '${item.quantity} ${localization.translate('unit_${item.unit}')}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.manufacturer.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.business,
                                        size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${item.manufacturer}${item.model.isNotEmpty ? ' - ${item.model}' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isCreator && _tender!.status != TenderStatus.closed
          ? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _tender!.validUntil.isAfter(DateTime.now())
                ? _bidOnTender
                : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(localization.translate('bid_on_tender')),
          ),
        ),
      )
          : null,
    );
  }
}