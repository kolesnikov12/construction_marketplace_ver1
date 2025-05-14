import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/providers/category_provider.dart';
import 'package:construction_marketplace/providers/item_provider.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';
import 'package:construction_marketplace/utils/responsive_helper.dart';
import 'package:construction_marketplace/utils/responsive_builder.dart';

class ListingItemForm extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onUpdate;

  const ListingItemForm({
    Key? key,
    required this.item,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ListingItemFormState createState() => _ListingItemFormState();
}

class _ListingItemFormState extends State<ListingItemForm> {
  final _itemNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String _selectedUnit = 'pcs'; // Default unit
  bool _isFree = false;

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
      _priceController.text = widget.item['price']?.toString() ?? '';
      _selectedUnit = widget.item['unit'] ?? 'pcs';
      _isFree = widget.item['isFree'] ?? false;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
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
      'price': _priceController.text,
      'isFree': _isFree,
    };

    widget.onUpdate(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        // For desktop and tablet, we'll use a multi-column layout
        if (!isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Category and Subcategory in 2 columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: DropdownButtonFormField<String>(
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
                    ),
                  ),

                  // Subcategory dropdown
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: DropdownButtonFormField<String>(
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
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Second row: Item Name with Autocomplete
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _itemNameController,
                  decoration: InputDecoration(
                    labelText: localization.translate('item_name') + ' *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _updateItemData();
                  },
                ),
                suggestionsCallback: (pattern) async {
                  if (_selectedCategoryId == null) return [];
                  return await Provider.of<ItemProvider>(context, listen: false)
                      .getSuggestions(pattern, _selectedCategoryId!, _selectedSubcategoryId);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _itemNameController.text = suggestion;
                  _updateItemData();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localization.translate('field_required');
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Third row: Manufacturer and Model in 2 columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manufacturer
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextFormField(
                        controller: _manufacturerController,
                        decoration: InputDecoration(
                          labelText: localization.translate('manufacturer'),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateItemData(),
                      ),
                    ),
                  ),

                  // Model
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: localization.translate('model'),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateItemData(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Fourth row: Quantity, Unit and Price with Free checkbox in a flexible layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
                  ),

                  // Unit
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                  ),

                  // Price
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: localization.translate('price_cad') + (_isFree ? '' : ' *'),
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                          enabled: !_isFree,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateItemData(),
                        validator: (value) {
                          if (!_isFree && (value == null || value.trim().isEmpty)) {
                            return localization.translate('field_required');
                          }
                          if (!_isFree && (double.tryParse(value!) == null || double.parse(value) < 0)) {
                            return localization.translate('enter_valid_number');
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Free checkbox
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: CheckboxListTile(
                        title: Text(localization.translate('free')),
                        value: _isFree,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _isFree = value!;
                            if (_isFree) {
                              _priceController.text = '';
                            }
                          });
                          _updateItemData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // For mobile, keep the original stacked layout with minimal changes
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

              // Subcategory Dropdown
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

              // Item Name with TypeAhead
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _itemNameController,
                  decoration: InputDecoration(
                    labelText: localization.translate('item_name') + ' *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _updateItemData();
                  },
                ),
                suggestionsCallback: (pattern) async {
                  if (_selectedCategoryId == null) return [];
                  return await Provider.of<ItemProvider>(context, listen: false)
                      .getSuggestions(pattern, _selectedCategoryId!, _selectedSubcategoryId);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _itemNameController.text = suggestion;
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
              SizedBox(height: 12),

              // Price and Free Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: localization.translate('price_cad') + (_isFree ? '' : ' *'),
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                        enabled: !_isFree,
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateItemData(),
                      validator: (value) {
                        if (!_isFree && (value == null || value.trim().isEmpty)) {
                          return localization.translate('field_required');
                        }
                        if (!_isFree && (double.tryParse(value!) == null || double.parse(value) < 0)) {
                          return localization.translate('enter_valid_number');
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isFree,
                          onChanged: (value) {
                            setState(() {
                              _isFree = value!;
                              if (_isFree) {
                                _priceController.text = '';
                              }
                            });
                            _updateItemData();
                          },
                        ),
                        Expanded(
                          child: Text(localization.translate('free')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}