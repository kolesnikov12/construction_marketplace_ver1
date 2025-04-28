// lib/screens/listings/create_listing_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/models/listing.dart';
import 'package:construction_marketplace/models/tender.dart'; // For DeliveryOption enum
import 'package:construction_marketplace/providers/listing_provider.dart';
import 'package:construction_marketplace/providers/city_provider.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/widgets/listings/listing_item_form.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

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
  List<Map<String, dynamic>> _items = [{}]; // Start with one empty item

  final ImagePicker _picker = ImagePicker();

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid form
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
        id: '',  // This will be assigned by the backend
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

      // Navigate back to the listings list screen
      Navigator.of(context).pop();
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('error')),
          content: Text(error.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
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

    // If not free, price is required
    if (isValid && !(item['isFree'] ?? false)) {
      isValid = item['price'] != null && item['price'].isNotEmpty;
    }

    return isValid;
  }

  void _addItem() {
    setState(() {
      if (_items.length < 20) {  // Maximum 20 items allowed
        _items.add({});
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {  // Keep at least one item
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

      if (pickedImages != null && pickedImages.isNotEmpty) {
        // Check photo count limit
        if (_selectedPhotos.length + pickedImages.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('max_5_photos'))),
          );
          return;
        }

        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

        if (photo != null) {
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
    // Listing Title
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

    // Items Section
    Text(
    localization.translate('items'),
    style: Theme.of(context).textTheme.titleLarge,
    ),
    SizedBox(height: 8),

    // Items List
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

    // Add Item Button
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

    // Photos Section
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
    labelText: localization.translate('valid_for') + ' *',
    border: OutlineInputBorder(),
    ),
    items: [1, 2, 3, 4].map((int value) {
    return DropdownMenuItem<int>(
    value: value,
    child: Text('$value ${localization.translate(value == 1 ? 'week' : 'weeks')}'),
    );
    }).toList(),
    onChanged: (newValue) {
    setState(() {
    _validWeeks = newValue!;
    });
    },
    ),
    SizedBox(height: 16),

    // Delivery Option
    Text(
    localization.translate('delivery') + ' *',
    style: Theme.of(context).textTheme.titleMedium,
    ),
    RadioListTile<DeliveryOption>(
    title: Text(localization.translate('pickup_only')),
    value: DeliveryOption.pickup,
    groupValue: _deliveryOption,
    onChanged: (DeliveryOption? value) {
    setState(() {
    _deliveryOption = value!;
    });
    },
    ),
    RadioListTile<DeliveryOption>(
    title: Text(localization.translate('can_ship')),
    value: DeliveryOption.delivery,
    groupValue: _deliveryOption,
    onChanged: (DeliveryOption? value) {
    setState(() {
    _deliveryOption = value!;
    });
    },
    ),
    RadioListTile<DeliveryOption>(
    title: Text(localization.translate('requires_discussion')),
    value: DeliveryOption.discuss,
    groupValue: _deliveryOption,
    onChanged: (DeliveryOption? value) {
    setState(() {
    _deliveryOption = value!;
    });
    },
    ),
    SizedBox(height: 16),

    // Description
    TextFormField(
    controller: _descriptionController,
    decoration: InputDecoration(
    labelText: localization.translate('description'),
    border: OutlineInputBorder(),
    alignLabelWithHint: true,
    ),
    maxLines: 5,
    ),
    SizedBox(height: 32),

    // Submit Button
    Center(
    child: ElevatedButton(
    onPressed: _submitForm,
    style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
    ),
    child: Text(
    localization.translate('create_listing'),
    style: TextStyle(fontSize: 16),
    ),
    ),
    ),
    SizedBox(height: 24),
    ],
    ),
    ),
    ),
    ),
    ),
    );
    }
  }
  );
  // Add only what we can
  pickedImages = pickedImages.take(5 - _selectedPhotos.length).toList();
}

List<File> newPhotos = pickedImages.map((xFile) => File(xFile.path)).toList();

setState(() {
_selectedPhotos.addAll(newPhotos);
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
if (_selectedPhotos.length >= 5) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(AppLocalizations.of(context)!