import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../models/basic_models.dart';

class TenderListItem extends StatelessWidget {
  final Tender tender;
  final VoidCallback onTap;
  final Widget Function(BuildContext)? trailingBuilder;

  const TenderListItem({
    Key? key,
    required this.tender,
    required this.onTap,
    this.trailingBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final tenderProvider = Provider.of<TenderProvider>(context, listen: false);

    // Check if tender is a favorite
    final isFavorite = tenderProvider.favoriteTenders.any((item) => item.id == tender.id);

    // Format currency
    final formatter = NumberFormat.currency(symbol: '\, decimalDigits: 0');

        // Format date
        final dateFormatter = DateFormat('MMM d, yyyy');

    // Determine if tender is active
    final isActive = (tender.status == TenderStatus.open || tender.status == TenderStatus.extended) &&
        tender.validUntil.isAfter(DateTime.now());

    // Get category names
    final categoryNames = tender.items.map((item) {
      final categoryName = categoryProvider.getCategoryName(item.categoryId, localization.isEnglish());
      return categoryName;
    }).toSet().toList(); // Use a Set to remove duplicates, then convert back to List

    // Status color
    Color statusColor;
    switch (tender.status) {
      case TenderStatus.open:
        statusColor = Colors.green;
        break;
      case TenderStatus.extended:
        statusColor = Colors.blue;
        break;
      case TenderStatus.closed:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title, Status and Budget
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tender.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Budget
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatter.format(tender.budget),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Status and Date Row
              Row(
                children: [
                  // Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tender.status == TenderStatus.open ? Icons.circle :
                          (tender.status == TenderStatus.extended ? Icons.update : Icons.check_circle),
                          size: 12,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          localization.translate(tender.status.name),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  // Valid Until
                  if (isActive) ...[
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${localization.translate('until')} ${dateFormatter.format(tender.validUntil)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  Spacer(),

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () async {
                      try {
                        await tenderProvider.toggleFavoriteTender(tender.id);
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

                  // Custom Trailing Widget (if provided)
                  if (trailingBuilder != null)
                    trailingBuilder!(context),
                ],
              ),

              SizedBox(height: 8),

              // Categories Row
              if (categoryNames.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: categoryNames.map((category) => Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                    label: Text(
                      category,
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.grey[200],
                  )).toList(),
                ),
                SizedBox(height: 8),
              ],

              // Items Count and Location Row
              Row(
                children: [
                  // Items count
                  Icon(Icons.format_list_bulleted, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${tender.items.length} ${localization.translate(tender.items.length == 1 ? 'item' : 'items')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Location
                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    tender.city,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Delivery Option
                  Icon(
                    tender.deliveryOption == DeliveryOption.pickup
                        ? Icons.store
                        : (tender.deliveryOption == DeliveryOption.delivery
                        ? Icons.local_shipping
                        : Icons.question_answer),
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    tender.deliveryOption == DeliveryOption.pickup
                        ? localization.translate('pickup_only')
                        : (tender.deliveryOption == DeliveryOption.delivery
                        ? localization.translate('delivery_required')
                        : localization.translate('requires_discussion')),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}