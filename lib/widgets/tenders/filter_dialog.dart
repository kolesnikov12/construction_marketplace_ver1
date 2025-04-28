import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/city_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

class FilterDialog extends StatefulWidget {
  final String? initialCity;
  final String? initialCategoryId;
  final bool showUserBids;
  final bool showUnviewed;

  const FilterDialog({
    Key? key,
    this.initialCity,
    this.initialCategoryId,
    this.showUserBids = false,
    this.showUnviewed = false,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String? _selectedCity;
  late String? _selectedCategoryId;
  late bool _showUserBids;
  late bool _showUnviewed;

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedCategoryId = widget.initialCategoryId;
    _showUserBids = widget.showUserBids;
    _showUnviewed = widget.showUnviewed;

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
      title: Text(localization.translate('filter_tenders')),
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

            // User Bids
            CheckboxListTile(
              title: Text(localization.translate('tenders_with_my_bids')),
              value: _showUserBids,
              onChanged: (value) {
                setState(() {
                  _showUserBids = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Unviewed
            CheckboxListTile(
              title: Text(localization.translate('unviewed_tenders')),
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
              'showUserBids': _showUserBids,
              'showUnviewed': _showUnviewed,
            });
          },
          child: Text(localization.translate('apply')),
        ),
      ],
    );
  }
}