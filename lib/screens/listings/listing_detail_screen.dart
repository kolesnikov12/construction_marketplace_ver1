import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/auth_provider.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';

import '../../models/enums.dart';
import '../../models/listing.dart';

class ListingDetailScreen extends StatefulWidget {
  static const routeName = '/listings/detail';

  @override
  _ListingDetailScreenState createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isLoading = true;
  Listing? _listing;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadListing();
  }

  Future<void> _loadListing() async {
    setState(() {
      _isLoading = true;
    });

    final listingId = ModalRoute.of(context)!.settings.arguments as String;

    try {
      final listing = await Provider.of<ListingProvider>(context, listen: false)
          .fetchListingById(listingId);

      setState(() {
        _listing = listing;
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
    if (_listing == null) return;

    try {
      await Provider.of<ListingProvider>(context, listen: false)
          .toggleFavoriteListing(_listing!.id);

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

  Future<void> _contactSeller() async {
    if (_listing == null) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('login_to_contact')),
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

    // In a real app, this would initiate a chat or show contact info
    // For demo, show a dialog with mock contact info
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text(
                AppLocalizations.of(context)!.translate('contact_seller')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLocalizations.of(context)!.translate('email')}: seller@example.com'),
                SizedBox(height: 8),
                Text('${AppLocalizations.of(context)!.translate('phone')}: +1 123-456-7890'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)!.translate('close')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  // Launch email
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'seller@example.com',
                    query: encodeQueryParameters({
                      'subject': 'Inquiry about "${_listing!.title}"',
                    }),
                  );
                  await launchUrl(emailLaunchUri);
                },
                child: Text(
                    AppLocalizations.of(context)!.translate('send_email')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  // Launch phone call
                  final Uri callLaunchUri = Uri(
                    scheme: 'tel',
                    path: '+11234567890',
                  );
                  await launchUrl(callLaunchUri);
                },
                child: Text(AppLocalizations.of(context)!.translate('call')),
              ),
            ],
          ),
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildImageCarousel() {
    if (_listing?.photoUrls == null || _listing!.photoUrls!.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 350,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _listing!.photoUrls!.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  _listing!.photoUrls![index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey[500]),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.translate('image_load_error'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_listing!.photoUrls!.length > 1) ...[
            SizedBox(height: 16),
            // Thumbnail navigation
            Container(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _listing!.photoUrls!.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentImageIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Image.network(
                        _listing!.photoUrls![index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);

    // Check if listing is a favorite
    final isFavorite = _listing != null &&
        listingProvider.favoriteListings.any((item) => item.id == _listing!.id);

    // Check if user is the listing creator
    final isCreator = _listing != null && authProvider.user != null &&
        _listing!.userId == authProvider.user!.id;

    // Format currency
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Format date
    final dateFormatter = DateFormat('MMMM d, yyyy');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localization.translate('listing_details')),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localization.translate('listing_details')),
        ),
        body: Center(
          child: Text(localization.translate('listing_not_found')),
        ),
      );
    }

    // Determine listing status message and color
    String statusMessage;
    Color statusColor;

    switch (_listing!.status) {
      case ListingStatus.available:
        if (_listing!.validUntil.isAfter(DateTime.now())) {
          statusMessage = localization.translate('available');
          statusColor = Colors.green;
        } else {
          statusMessage = localization.translate('expired');
          statusColor = Colors.orange;
        }
        break;
      case ListingStatus.sold:
        statusMessage = localization.translate('sold');
        statusColor = Colors.blue;
        break;
      case ListingStatus.expired:
        statusMessage = localization.translate('expired');
        statusColor = Colors.orange;
        break;
    }

    // Desktop layout with two panels
    if (isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(localization.translate('listing_details')),
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
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side navigation
            SizedBox(
              width: 240,
              child: AppDrawer(),
            ),

            // Left panel - Image and price section
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _listing!.status == ListingStatus.available
                                  ? Icons.check_circle
                                  : (_listing!.status == ListingStatus.sold
                                  ? Icons.shopping_cart
                                  : Icons.access_time),
                              color: statusColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              statusMessage,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Image gallery
                      _buildImageCarousel(),

                      SizedBox(height: 24),

                      // Price section in a card
                      if (_listing!.items.isNotEmpty)
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localization.translate('price'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _listing!.items.first.isFree
                                      ? localization.translate('free')
                                      : formatter.format(_listing!.items.first.price),
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: _listing!.items.first.isFree
                                        ? Colors.green
                                        : Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Divider(height: 32),

                                // Location & delivery info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localization.translate('location'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _listing!.city,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localization.translate('delivery'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _listing!.deliveryOption == DeliveryOption.pickup
                                                ? localization.translate('pickup_only')
                                                : (_listing!.deliveryOption == DeliveryOption.delivery
                                                ? localization.translate('can_ship')
                                                : localization.translate('requires_discussion')),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16),

                                // Valid until date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      localization.translate('valid_until'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      dateFormatter.format(_listing!.validUntil),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      // Contact seller button (for non-creators only)
                      if (!isCreator && _listing!.status == ListingStatus.available)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _contactSeller,
                            icon: Icon(Icons.email),
                            label: Text(
                              localization.translate('contact_seller'),
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Right panel - Listing details
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _listing!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Description
                      if (_listing!.description != null && _listing!.description!.isNotEmpty) ...[
                        Text(
                          localization.translate('description'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            _listing!.description!,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Items section
                      Text(
                        localization.translate('items'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Enhanced items list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _listing!.items.length,
                        itemBuilder: (ctx, index) {
                          final item = _listing!.items[index];
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
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.itemName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: item.isFree ? Colors.green[50] : Colors.blue[50],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          item.isFree
                                              ? localization.translate('free')
                                              : formatter.format(item.price),
                                          style: TextStyle(
                                            color: item.isFree ? Colors.green[700] : Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12),

                                  // Category & Quantity Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              localization.translate('category'),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              subcategoryName != null
                                                  ? '$categoryName > $subcategoryName'
                                                  : categoryName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              localization.translate('quantity'),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${item.quantity} ${localization.translate('unit_${item.unit}')}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Manufacturer & Model
                                  if (item.manufacturer != null && item.manufacturer!.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Divider(),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localization.translate('manufacturer'),
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                item.manufacturer!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (item.model != null && item.model!.isNotEmpty)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  localization.translate('model'),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  item.model!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
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
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout (original)
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(localization.translate('listing_details')),
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
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _listing!.status == ListingStatus.available
                        ? Icons.check_circle
                        : (_listing!.status == ListingStatus.sold
                        ? Icons.shopping_cart
                        : Icons.access_time),
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
                  if (_listing!.status == ListingStatus.available) ...[
                    Text(
                      ' • ${localization.translate('valid_until')} ${dateFormatter.format(_listing!.validUntil)}',
                      style: TextStyle(
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Image Carousel
            if (_listing!.photoUrls != null && _listing!.photoUrls!.isNotEmpty)
              Stack(
                children: [
                  // Carousel
                  Container(
                    height: 250,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: _listing!.photoUrls!.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          _listing!.photoUrls![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, size: 64),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Navigation arrows
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        final newIndex = _currentImageIndex > 0
                            ? _currentImageIndex - 1
                            : _listing!.photoUrls!.length - 1;
                        setState(() {
                          _currentImageIndex = newIndex;
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.all(8),
                        child: Icon(
                            Icons.arrow_back_ios, color: Colors.white70),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        final newIndex = _currentImageIndex < _listing!.photoUrls!.length - 1
                            ? _currentImageIndex + 1
                            : 0;
                        setState(() {
                          _currentImageIndex = newIndex;
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.all(8),
                        child: Icon(
                            Icons.arrow_forward_ios, color: Colors.white70),
                      ),
                    ),
                  ),

                  // Indicator dots
                  if (_listing!.photoUrls!.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _listing!.photoUrls!.asMap().entries.map((
                            entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                      Icons.image_not_supported, size: 64, color: Colors.grey),
                ),
              ),

            // Title & Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _listing!.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _listing!.city,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  // Delivery
                  Row(
                    children: [
                      Icon(
                        _listing!.deliveryOption == DeliveryOption.pickup
                            ? Icons.store
                            : (_listing!.deliveryOption ==
                            DeliveryOption.delivery
                            ? Icons.local_shipping
                            : Icons.question_answer),
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _listing!.deliveryOption == DeliveryOption.pickup
                            ? localization.translate('pickup_only')
                            : (_listing!.deliveryOption ==
                            DeliveryOption.delivery
                            ? localization.translate('can_ship')
                            : localization.translate('requires_discussion')),
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Description (if available)
                  if (_listing!.description != null &&
                      _listing!.description!.isNotEmpty) ...[
                    Text(
                      localization.translate('description'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _listing!.description!,
                      style: TextStyle(
                        fontSize: 16,
                      ),
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
                    itemCount: _listing!.items.length,
                    itemBuilder: (ctx, index) {
                      final item = _listing!.items[index];
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

                              // Price
                              Text(
                                item.isFree
                                    ? localization.translate('free')
                                    : formatter.format(item.price),
                                style: TextStyle(
                                  color: item.isFree ? Colors.green : Colors
                                      .blue[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              SizedBox(height: 8),

                              // Category & Subcategory
                              Row(
                                children: [
                                  Icon(Icons.category, size: 14,
                                      color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      subcategoryName != null
                                          ? '$categoryName > $subcategoryName'
                                          : categoryName,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),

                              // Quantity & Unit
                              Row(
                                children: [
                                  Icon(Icons.format_list_numbered, size: 14,
                                      color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    '${item.quantity} ${localization.translate(
                                        'unit_${item.unit}')}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              // Manufacturer & Model (if available)
                              if (item.manufacturer != null &&
                                  item.manufacturer!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.business, size: 14,
                                        color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${item.manufacturer}${item.model !=
                                          null && item.model!.isNotEmpty
                                          ? ' - ${item.model}'
                                          : ''}',
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
      bottomNavigationBar: !isCreator && _listing!.status == ListingStatus.available
          ? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _contactSeller,
            child: Text(localization.translate('contact_seller')),
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