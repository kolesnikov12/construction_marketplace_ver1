import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/listing.dart';

class ListingGridItem extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final Widget Function(BuildContext)? actionBuilder;
  final bool isDesktopView;

  const ListingGridItem({
    Key? key,
    required this.listing,
    required this.onTap,
    this.actionBuilder,
    this.isDesktopView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(context, listen: false);

    // Check if listing is a favorite
    final isFavorite = listingProvider.favoriteListings.any((item) => item.id == listing.id);

    // Format currency
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Format date
    final dateFormatter = DateFormat('MMM d, yyyy');

    // Determine if listing is active
    final isActive = listing.status == ListingStatus.available &&
        listing.validUntil.isAfter(DateTime.now());

    // Get category names
    final categoryNames = listing.items.map((item) {
      final categoryName = categoryProvider.getCategoryName(item.categoryId, localization.isEnglish());
      return categoryName;
    }).toSet().toList(); // Use a Set to remove duplicates, then convert back to List

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: isDesktopView
            ? _buildDesktopLayout(
            context,
            localization,
            formatter,
            dateFormatter,
            isActive,
            categoryNames,
            isFavorite,
            listingProvider)
            : _buildMobileLayout(
            context,
            localization,
            formatter,
            dateFormatter,
            isActive,
            categoryNames,
            isFavorite,
            listingProvider),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      AppLocalizations localization,
      NumberFormat formatter,
      DateFormat dateFormatter,
      bool isActive,
      List<String> categoryNames,
      bool isFavorite,
      ListingProvider listingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Stack(
          children: [
            Container(
              height: 180, // Taller image on desktop
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: listing.photoUrls != null && listing.photoUrls!.isNotEmpty
                  ? Image.network(
                listing.photoUrls![0],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image, size: 40));
                },
              )
                  : Center(child: Icon(Icons.photo, size: 40)),
            ),
            // Status badge
            if (listing.status != ListingStatus.available)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: listing.status == ListingStatus.sold
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing.status == ListingStatus.sold
                        ? localization.translate('sold')
                        : localization.translate('expired'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Favorite button
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () async {
                    try {
                      await listingProvider.toggleFavoriteListing(listing.id);
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),

                // Price
                if (listing.items.isNotEmpty)
                  Text(
                    listing.items.first.isFree
                        ? localization.translate('free')
                        : formatter.format(listing.items.first.price),
                    style: TextStyle(
                      color: listing.items.first.isFree ? Colors.green : Colors.blueGrey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                // Valid until
                if (isActive)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${localization.translate('until')} ${dateFormatter.format(listing.validUntil)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 4),

                // Category
                if (categoryNames.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            categoryNames.join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Delivery
                Row(
                  children: [
                    Icon(
                      listing.deliveryOption == DeliveryOption.pickup
                          ? Icons.store
                          : (listing.deliveryOption == DeliveryOption.delivery
                          ? Icons.local_shipping
                          : Icons.question_answer),
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      listing.deliveryOption == DeliveryOption.pickup
                          ? localization.translate('pickup_only')
                          : (listing.deliveryOption == DeliveryOption.delivery
                          ? localization.translate('can_ship')
                          : localization.translate('requires_discussion')),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // View details button (desktop only)
                if (isDesktopView) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      child: Text(localization.translate('view_details')),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Actions (if any)
        if (actionBuilder != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 4),
            child: actionBuilder!(context),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context,
      AppLocalizations localization,
      NumberFormat formatter,
      DateFormat dateFormatter,
      bool isActive,
      List<String> categoryNames,
      bool isFavorite,
      ListingProvider listingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Stack(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: listing.photoUrls != null && listing.photoUrls!.isNotEmpty
                  ? Image.network(
                listing.photoUrls![0],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image, size: 40));
                },
              )
                  : Center(child: Icon(Icons.photo, size: 40)),
            ),
            // Status badge
            if (listing.status != ListingStatus.available)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: listing.status == ListingStatus.sold
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing.status == ListingStatus.sold
                        ? localization.translate('sold')
                        : localization.translate('expired'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Favorite button
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () async {
                    try {
                      await listingProvider.toggleFavoriteListing(listing.id);
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),

                // Price
                if (listing.items.isNotEmpty)
                  Text(
                    listing.items.first.isFree
                        ? localization.translate('free')
                        : formatter.format(listing.items.first.price),
                    style: TextStyle(
                      color: listing.items.first.isFree ? Colors.green : Colors.blueGrey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Valid until
                if (isActive)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${localization.translate('until')} ${dateFormatter.format(listing.validUntil)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                // Category
                if (categoryNames.isNotEmpty)
                  Expanded(
                    child: Text(
                      categoryNames.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Delivery
                Row(
                  children: [
                    Icon(
                      listing.deliveryOption == DeliveryOption.pickup
                          ? Icons.store
                          : (listing.deliveryOption == DeliveryOption.delivery
                          ? Icons.local_shipping
                          : Icons.question_answer),
                      size: 14,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      listing.deliveryOption == DeliveryOption.pickup
                          ? localization.translate('pickup_only')
                          : (listing.deliveryOption == DeliveryOption.delivery
                          ? localization.translate('can_ship')
                          : localization.translate('requires_discussion')),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Actions (if any)
        if (actionBuilder != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 4),
            child: actionBuilder!(context),
          ),
      ],
    );
  }
}