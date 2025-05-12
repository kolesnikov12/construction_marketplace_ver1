import 'dart:developer' as developer;
import 'dart:ui' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

    final tenderId = ModalRoute
        .of(context)!
        .settings
        .arguments as String;

    try {
      final tender = await Provider
          .of<TenderProvider>(context, listen: false)
          .fetchTenderById(tenderId);

      setState(() {
        _tender = tender;
        _isLoading = false;
      });
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(
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
      await Provider
          .of<TenderProvider>(context, listen: false)
          .toggleFavoriteTender(_tender!.id);

      setState(() {}); // Refresh UI to update favorite icon
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

    final user = Provider
        .of<AuthProvider>(context, listen: false)
        .user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('login_to_bid')),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.translate('login'),
            onPressed: () {
              // Navigate to login screen
            },
          ),
        ),
      );
      return;
    }

    // In a real app, this would open a bid form
    // For demo, show a dialog with a simple success message
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text(
                AppLocalizations.of(context)!.translate('bid_on_tender')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.translate(
                    'bid_on_tender_confirm')),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate(
                        'bid_amount'),
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate(
                        'bid_message'),
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
                      content: Text(AppLocalizations.of(context)!.translate(
                          'bid_submitted')),
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


// Add this utility method for logging
  void _logDebug(String message) {
    developer.log(message, name: 'TenderDetailScreen');
    print('TenderDetailScreen: $message');
  }


// In your build method where the attachments are rendered:
  Widget _buildAttachmentsList() {
    if (_tender?.attachmentUrls == null || _tender!.attachmentUrls!.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'attachments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 8),

        // Direct rendering of attachments
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _tender!.attachmentUrls!.length,
          itemBuilder: (ctx, index) {
            final url = _tender!.attachmentUrls![index];
            _logDebug('Processing attachment URL: $url');

            // Try to determine if it's an image by URL
            final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(
                  (ext) => url.toLowerCase().contains(ext),
            );
            _logDebug('Is image determined by extension: $isImage');

            // Decode the URL
            String decodedUrl;
            try {
              decodedUrl = Uri.decodeFull(url);
              _logDebug('Decoded URL: $decodedUrl');
            } catch (e) {
              _logDebug('Error decoding URL: $e');
              decodedUrl = url;
            }

            // For images, show a preview with tap to expand
            if (isImage) {
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openAttachment(url),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4)),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          child: Builder(
                              builder: (context) {
                                _logDebug(
                                    'Attempting to render image: $decodedUrl');
                                return Image.network(
                                  decodedUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child,
                                      loadingProgress) {
                                    if (loadingProgress == null) {
                                      _logDebug('Image loaded successfully');
                                      return child;
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                            .expectedTotalBytes != null
                                            ? loadingProgress
                                            .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    _logDebug('Error loading image: $error');
                                    _logDebug('Stack trace: $stackTrace');

                                    // Try with the original URL as fallback
                                    return Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        _logDebug(
                                            'Error loading with original URL: $error');

                                        // Show error UI
                                        return Container(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.broken_image, size: 36,
                                                  color: Colors.red),
                                              SizedBox(height: 8),
                                              Text('Could not load image'),
                                              SizedBox(height: 8),
                                              Text(url, style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.image, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                decodedUrl
                                    .split('/')
                                    .last
                                    .split('?')
                                    .first,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                                Icons.fullscreen, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // For non-image files, show just a list item
              final fileName = decodedUrl
                  .split('/')
                  .last
                  .split('?')
                  .first;
              final extension = fileName.contains('.') ? fileName
                  .split('.')
                  .last
                  .toLowerCase() : '';

              return ListTile(
                leading: Icon(_getFileIcon(extension)),
                title: Text(fileName),
                subtitle: Text('tap_to_open'),
                onTap: () => _openAttachment(url),
              );
            }
          },
        ),
      ],
    );
  }

// Updated _openAttachment with more robust URL handling
  Future<void> _openAttachment(String url) async {
    final localization = AppLocalizations.of(context)!;
    _logDebug('Opening attachment: $url');

    // First, properly decode the URL which might be encoded
    String decodedUrl;
    try {
      decodedUrl = Uri.decodeFull(url);
      _logDebug('Decoded URL: $decodedUrl');
    } catch (e) {
      _logDebug('Error decoding URL: $e');
      decodedUrl = url;
    }

    // Try different URL cleaning approaches
    String cleanUrl = decodedUrl;

    // Special Firebase Storage URL handling
    if (decodedUrl.contains('firebasestorage.googleapis.com') ||
        decodedUrl.contains('storage.googleapis.com')) {
      _logDebug('Detected Firebase Storage URL');

      // If the URL is totally messed up, try to extract the actual URL part
      if (decodedUrl.contains('https://')) {
        int httpsIndex = decodedUrl.indexOf('https://');
        if (httpsIndex > 0) {
          cleanUrl = decodedUrl.substring(httpsIndex);
          _logDebug('Extracted URL from string: $cleanUrl');
        }
      }

      // Handle token parameter if needed
      if (cleanUrl.contains('token=')) {
        try {
          final uri = Uri.parse(cleanUrl);
          final token = uri.queryParameters['token'];
          if (token != null) {
            // Reconstruct a clean URL with just the token parameter
            cleanUrl = Uri(
              scheme: uri.scheme,
              host: uri.host,
              path: uri.path,
              queryParameters: {'alt': 'media', 'token': token},
            ).toString();
            _logDebug('Cleaned URL with token: $cleanUrl');
          }
        } catch (e) {
          _logDebug('Error parsing URL for token extraction: $e');
        }
      }
    }

    // Check if it's an image file
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(
          (ext) => cleanUrl.toLowerCase().contains(ext),
    );
    _logDebug('Is image by extension check: $isImage');

    if (isImage) {
      // For images, show in a full-screen image viewer
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) =>
            Dialog(
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
                      // Add download button
                      IconButton(
                        icon: Icon(Icons.download),
                        tooltip: localization.translate('download_image'),
                        onPressed: () async {
                          try {
                            _logDebug(
                                'Attempting to launch for download: $cleanUrl');
                            final Uri uri = Uri.parse(cleanUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode
                                  .externalApplication);
                            } else {
                              _logDebug('Cannot launch URL');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cannot open URL')),
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
                        child: Builder(
                            builder: (context) {
                              _logDebug(
                                  'Rendering image in fullscreen: $cleanUrl');
                              return Image.network(
                                cleanUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child,
                                    loadingProgress) {
                                  if (loadingProgress == null) {
                                    _logDebug(
                                        'Fullscreen image loaded successfully');
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                          .expectedTotalBytes != null
                                          ? loadingProgress
                                          .cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  _logDebug(
                                      'Error loading fullscreen image: $error');

                                  // Try alternate URL as fallback
                                  return Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      _logDebug(
                                          'Error loading with original URL: $error');
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Icon(Icons.error, color: Colors.red,
                                              size: 48),
                                          SizedBox(height: 16),
                                          Text(
                                            'Could not load image',
                                            style: TextStyle(
                                                color: Colors.white),
                                          ),
                                          SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                final Uri uri = Uri.parse(
                                                    cleanUrl);
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              } catch (e) {
                                                _logDebug(
                                                    'Error opening in browser: $e');
                                              }
                                            },
                                            child: Text('Open in Browser'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            }
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    } else {
      // For non-image files, show options dialog
      _logDebug('Showing options dialog for non-image file');
      showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              title: Text(localization.translate('open_attachment')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose how to open this file'),
                  SizedBox(height: 16),
                  // Display file name
                  Row(
                    children: [
                      Icon(_getFileIcon(cleanUrl
                          .split('.')
                          .last
                          .toLowerCase())),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cleanUrl
                              .split('/')
                              .last
                              .split('?')
                              .first,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(cleanUrl,
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(localization.translate('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    _logDebug('Attempting to open in browser: $cleanUrl');
                    try {
                      final Uri uri = Uri.parse(cleanUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                            uri, mode: LaunchMode.externalApplication);
                        Navigator.of(ctx).pop();
                      } else {
                        _logDebug('Cannot launch URL');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot open URL')),
                        );
                      }
                    } catch (e) {
                      _logDebug('Error launching URL: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text('Open in Browser'),
                ),
              ],
            ),
      );
    }
  }



// Helper method to get appropriate icon for file type
  IconData _getFileIcon(String url) {
  final extension = url.split('.').last.toLowerCase();

  switch (extension) {
  case 'pdf':
  return Icons.picture_as_pdf;
  case 'doc':
  case 'docx':
  return Icons.description;
  case 'xls':
  case 'xlsx':
  return Icons.table_chart;
  case 'zip':
  case 'rar':
  return Icons.archive;
  case 'jpg':
  case 'jpeg':
  case 'png':
  case 'gif':
  case 'webp':
  return Icons.image;
  default:
  return Icons.insert_drive_file;
  }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderProvider = Provider.of<TenderProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if tender is a favorite
    final isFavorite =
        tenderProvider.favoriteTenders.any((item) => item.id == _tender!.id);

    // Check if user is the tender creator
    final isCreator = _tender != null && authProvider.user != null &&
        _tender!.userId == authProvider.user!.id;

    // Format currency
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Format date
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

    // Determine tender status message and color
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
        title: Text(localization.translate('tender_details')),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
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
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tender!.status == TenderStatus.open || _tender!.status == TenderStatus.extended
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

            // Title & Budget
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _tender!.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Budget
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money, color: Colors.blue[800], size: 20),
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

                  // Location & Delivery
                  Row(
                    children: [
                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tender!.city,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delivery
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _tender!.deliveryOption == DeliveryOption.pickup
                                  ? Icons.store
                                  : (_tender!.deliveryOption == DeliveryOption.delivery
                                  ? Icons.local_shipping
                                  : Icons.question_answer),
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _tender!.deliveryOption == DeliveryOption.pickup
                                    ? localization.translate('pickup_only')
                                    : (_tender!.deliveryOption == DeliveryOption.delivery
                                    ? localization.translate('delivery_required')
                                    : localization.translate('requires_discussion')),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Description (if available)
                  if (_tender!.description != null && _tender!.description!.isNotEmpty) ...[
                    Text(
                      localization.translate('description'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tender!.description!,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Attachments (if available)
                  if (_tender!.attachmentUrls != null && _tender!.attachmentUrls!.isNotEmpty) ...[
                    Text(
                      localization.translate('attachments'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Attachments List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _tender!.attachmentUrls!.length,
                      itemBuilder: (ctx, index) {
                        final url = _tender!.attachmentUrls![index];
                        final fileName = url.split('/').last;
                        final extension = fileName.split('.').last.toLowerCase();

                        IconData icon;
                        switch (extension) {
                          case 'pdf':
                            icon = Icons.picture_as_pdf;
                            break;
                          case 'doc':
                          case 'docx':
                            icon = Icons.description;
                            break;
                          case 'xls':
                          case 'xlsx':
                            icon = Icons.table_chart;
                            break;
                          case 'zip':
                          case 'rar':
                            icon = Icons.archive;
                            break;
                          case 'jpg':
                          case 'jpeg':
                          case 'png':
                            icon = Icons.image;
                            break;
                          default:
                            icon = Icons.insert_drive_file;
                        }

                        return ListTile(
                          leading: Icon(icon),
                          title: Text(fileName),
                          onTap: () => _buildAttachmentsList(),
                        );
                      },
                    ),

                    SizedBox(height: 24),
                  ],

                  // Items
                  Text(
                    localization.translate('items'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Items List
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
                      if (item.subcategoryId != null) {
                        subcategoryName = categoryProvider.getCategoryName(
                          item.subcategoryId!,
                          localization.isEnglish(),
                        );
                      }

                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item Name
                              Text(
                                item.itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              SizedBox(height: 8),

                              // Category & Subcategory
                              Row(
                                children: [
                                  Icon(Icons.category, size: 14, color: Colors.grey),
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

                              // Quantity & Unit
                              Row(
                                children: [
                                  Icon(Icons.format_list_numbered, size: 14, color: Colors.grey),
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

                              // Manufacturer & Model (if available)
                              if (item.manufacturer != null && item.manufacturer!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.business, size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${item.manufacturer}${item.model != null && item.model!.isNotEmpty ? ' - ${item.model}' : ''}',
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _tender!.validUntil.isAfter(DateTime.now())
                ? _bidOnTender
                : null,
            child: Text(localization.translate('bid_on_tender')),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      )
          : null,
    );
  }
}