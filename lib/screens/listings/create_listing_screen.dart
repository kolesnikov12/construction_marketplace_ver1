import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/city_provider.dart';

import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

import '../../models/basic_models.dart';
import '../../widgets/app_drawer.dart';
import 'listing_item_form.dart';

class CreateListingScreen extends StatefulWidget {
  static const routeName = '/create-listing';

  @override
  _CreateListingScreenState createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  DeliveryOption _deliveryOption = DeliveryOption.pickup;
  int _validWeeks = 1;
  List<File> _selectedPhotos = [];
  List<Map<String, dynamic>> _items = [{}];

  final ImagePicker _picker = ImagePicker();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty || _items.any((item) => !_isItemValid(item))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('listing_items_required'))),
      );
      return;
    }

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('at_least_one_photo_required'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final listingItems = _items.map((item) => ListingItem(
        id: '',
        categoryId: item['categoryId'],
        subcategoryId: item['subcategoryId'],
        itemName: item['itemName'],
        manufacturer: item['manufacturer'],
        model: item['model'],
        quantity: double.parse(item['quantity']),
        unit: item['unit'],
        price: item['isFree'] ? null : double.parse(item['price']),
        isFree: item['isFree'] ?? false,
      )).toList();

      await Provider.of<ListingProvider>(context, listen: false).createListing(
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        deliveryOption: _deliveryOption,
        validWeeks: _validWeeks,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        items: listingItems,
        photos: _selectedPhotos,
      );

      Navigator.of(context).pop();
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

  bool _isItemValid(Map<String, dynamic> item) {
    bool isValid = item['categoryId'] != null &&
        item['categoryId'].isNotEmpty &&
        item['itemName'] != null &&
        item['itemName'].isNotEmpty &&
        item['quantity'] != null &&
        item['quantity'].isNotEmpty &&
        item['unit'] != null &&
        item['unit'].isNotEmpty;

    if (isValid && !(item['isFree'] ?? false)) {
      isValid = item['price'] != null && item['price'].isNotEmpty;
    }
    return isValid;
  }

  void _addItem() {
    setState(() {
      if (_items.length < 20) {
        _items.add({});
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
      }
    });
  }

  void _updateItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
  }

  Future<void> _pickPhotos() async {
    try {
      List<XFile>? pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        if (_selectedPhotos.length + pickedImages.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('max_5_photos'))),
          );
          return;
        }
        setState(() {
          _selectedPhotos.addAll(pickedImages.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        if (_selectedPhotos.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('max_5_photos'))),
          );
          return;
        }
        setState(() {
          _selectedPhotos.add(File(photo.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('create_listing')),
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: localization.translate('listing_title') + ' *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localization.translate('field_required');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Items
                  Text(
                    localization.translate('items'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),

                  ...List.generate(_items.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${localization.translate('item')} ${index + 1}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (_items.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeItem(index),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ListingItemForm(
                                item: _items[index],
                                onUpdate: (updatedItem) => _updateItem(index, updatedItem),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  if (_items.length < 20)
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text(localization.translate('add_item')),
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  SizedBox(height: 24),

                  // Photos
                  Text(
                    localization.translate('photos') + ' *',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    localization.translate('at_least_one_photo_required_max_5'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 8),

                  if (_selectedPhotos.isNotEmpty)
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (ctx, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedPhotos[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _removePhoto(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16),

                  if (_selectedPhotos.length < 5)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.photo_library),
                          label: Text(localization.translate('pick_photos')),
                          onPressed: _pickPhotos,
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.camera_alt),
                          label: Text(localization.translate('take_photo')),
                          onPressed: _takePicture,
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // City
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: localization.translate('city') + ' *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return Provider.of<CityProvider>(context, listen: false)
                          .getSuggestions(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      _cityController.text = suggestion;
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localization.translate('field_required');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Valid Weeks
                  DropdownButtonFormField<int>(
                    value: _validWeeks,
                    decoration: InputDecoration(
                      labelText: localization.translate('valid_weeks'),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      final week = index + 1;
                      return DropdownMenuItem(
                        value: week,
                        child: Text('$week'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _validWeeks = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 24),

                  // Submit
                  Center(
                    child: ElevatedButton(
                      child: Text(localization.translate('submit')),
                      onPressed: _submitForm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}