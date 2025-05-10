// lib/widgets/tenders/tender_item_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

class TenderItemForm extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onUpdate;

  const TenderItemForm({
    Key? key,
    required this.item,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _TenderItemFormState createState() => _TenderItemFormState();
}

class _TenderItemFormState extends State<TenderItemForm> {
  final _itemNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String _selectedUnit = 'pcs'; // Default unit

  final List<String> _units = ['pcs', 'sq.m', 'm', 'cubic m', 'kg', 'ton', 'liter'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if available
    if (widget.item.isNotEmpty) {
      _selectedCategoryId = widget.item['categoryId'];
      _selectedSubcategoryId = widget.item['subcategoryId'];
      _itemNameController.text = widget.item['itemName'] ?? '';
      _manufacturerController.text = widget.item['manufacturer'] ?? '';
      _modelController.text = widget.item['model'] ?? '';
      _quantityController.text = widget.item['quantity']?.toString() ?? '';
      _selectedUnit = widget.item['unit'] ?? 'pcs';
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateItemData() {
    final updatedItem = {
      ...widget.item,
      'categoryId': _selectedCategoryId,
      'subcategoryId': _selectedSubcategoryId,
      'itemName': _itemNameController.text,
      'manufacturer': _manufacturerController.text,
      'model': _modelController.text,
      'quantity': _quantityController.text,
      'unit': _selectedUnit,
    };

    widget.onUpdate(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: localization.translate('category') + ' *',
            border: OutlineInputBorder(),
          ),
          hint: Text(localization.translate('select_category')),
          items: categoryProvider.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(localization.isEnglish() ? category.nameEn : category.nameFr),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
              _selectedSubcategoryId = null; // Reset subcategory when category changes
            });
            _updateItemData();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localization.translate('field_required');
            }
            return null;
          },
        ),
        SizedBox(height: 12),

        // Subcategory Dropdown (only enabled if a category is selected)
        DropdownButtonFormField<String>(
          value: _selectedSubcategoryId,
          decoration: InputDecoration(
            labelText: localization.translate('subcategory'),
            border: OutlineInputBorder(),
          ),
          hint: Text(localization.translate('select_subcategory')),
          items: (_selectedCategoryId != null && categoryProvider.getSubcategories(_selectedCategoryId!).isNotEmpty)
              ? categoryProvider.getSubcategories(_selectedCategoryId!).map((subcategory) {
            return DropdownMenuItem<String>(
              value: subcategory.id,
              child: Text(localization.isEnglish() ? subcategory.nameEn : subcategory.nameFr),
            );
          }).toList()
              : null,
          onChanged: _selectedCategoryId == null
              ? null
              : (value) {
            setState(() {
              _selectedSubcategoryId = value;
            });
            _updateItemData();
          },
        ),
        SizedBox(height: 12),

        // Item Name - Using a regular TextFormField instead of TypeAheadFormField
        TextFormField(
          controller: _itemNameController,
          decoration: InputDecoration(
            labelText: localization.translate('item_name') + ' *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _updateItemData();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localization.translate('field_required');
            }
            return null;
          },
        ),
        SizedBox(height: 12),

        // Manufacturer/Model Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manufacturerController,
                decoration: InputDecoration(
                  labelText: localization.translate('manufacturer'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateItemData(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: localization.translate('model'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateItemData(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Quantity/Unit Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: localization.translate('quantity') + ' *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateItemData(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localization.translate('field_required');
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return localization.translate('enter_valid_number');
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: localization.translate('unit') + ' *',
                  border: OutlineInputBorder(),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(localization.translate('unit_$unit')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                  _updateItemData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}