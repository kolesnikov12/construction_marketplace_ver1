import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/city_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

import '../../models/basic_models.dart';

class ListingFilterDialog extends StatefulWidget {
  final String? initialCity;
  final String? initialCategoryId;
  final bool showUnviewed;
  final List<String> selectedDeliveryOptions;

  const ListingFilterDialog({
    Key? key,
    this.initialCity,
    this.initialCategoryId,
    this.showUnviewed = false,
    this.selectedDeliveryOptions = const [],
  }) : super(key: key);

  @override
  _ListingFilterDialogState createState() => _ListingFilterDialogState();
}

class _ListingFilterDialogState extends State<ListingFilterDialog> {
  late String? _selectedCity;
  late String? _selectedCategoryId;
  late bool _showUnviewed;
  late List<String> _selectedDeliveryOptions;

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedCategoryId = widget.initialCategoryId;
    _showUnviewed = widget.showUnviewed;
    _selectedDeliveryOptions = List.from(widget.selectedDeliveryOptions);

    if (_selectedCity != null) {
      _cityController.text = _selectedCity!;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return AlertDialog(
      title: Text(localization.translate('filter_listings')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City
            Text(
              localization.translate('city'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: localization.translate('select_city'),
                  border: OutlineInputBorder(),
                  suffixIcon: _selectedCity != null
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedCity = null;
                        _cityController.clear();
                      });
                    },
                  )
                      : null,
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await Provider.of<CityProvider>(context, listen: false)
                    .getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  _selectedCity = suggestion;
                  _cityController.text = suggestion;
                });
              },
            ),

            SizedBox(height: 16),

            // Category
            Text(
              localization.translate('category'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                hintText: localization.translate('select_category'),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(localization.translate('all_categories')),
                ),
                ...categoryProvider.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(localization.isEnglish() ? category.nameEn : category.nameFr),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),

            SizedBox(height: 16),

            // Delivery Options
            Text(
              localization.translate('delivery_options'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),

            // Pickup
            CheckboxListTile(
              title: Text(localization.translate('pickup_only')),
              value: _selectedDeliveryOptions.contains(DeliveryOption.pickup.name),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedDeliveryOptions.contains(DeliveryOption.pickup.name)) {
                      _selectedDeliveryOptions.add(DeliveryOption.pickup.name);
                    }
                  } else {
                    _selectedDeliveryOptions.remove(DeliveryOption.pickup.name);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Delivery
            CheckboxListTile(
              title: Text(localization.translate('can_ship')),
              value: _selectedDeliveryOptions.contains(DeliveryOption.delivery.name),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedDeliveryOptions.contains(DeliveryOption.delivery.name)) {
                      _selectedDeliveryOptions.add(DeliveryOption.delivery.name);
                    }
                  } else {
                    _selectedDeliveryOptions.remove(DeliveryOption.delivery.name);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Discuss
            CheckboxListTile(
              title: Text(localization.translate('requires_discussion')),
              value: _selectedDeliveryOptions.contains(DeliveryOption.discuss.name),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedDeliveryOptions.contains(DeliveryOption.discuss.name)) {
                      _selectedDeliveryOptions.add(DeliveryOption.discuss.name);
                    }
                  } else {
                    _selectedDeliveryOptions.remove(DeliveryOption.discuss.name);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            SizedBox(height: 8),

            // Unviewed
            CheckboxListTile(
              title: Text(localization.translate('unviewed_listings')),
              value: _showUnviewed,
              onChanged: (value) {
                setState(() {
                  _showUnviewed = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'city': _selectedCity,
              'categoryId': _selectedCategoryId,
              'showUnviewed': _showUnviewed,
              'deliveryOptions': _selectedDeliveryOptions,
            });
          },
          child: Text(localization.translate('apply')),
        ),
      ],
    );
  }
}