
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:typed_data';

import '../../bloc/bloc_provider.dart';
import '../../bloc/listing_bloc.dart';
import '../../bloc/base/bloc_events.dart';
import '../../bloc/base/bloc_states.dart';
import '../../providers/city_provider.dart';
import '../../models/enums.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../widgets/app_drawer.dart';
import 'listing_item_form.dart';

// A class to handle both web and mobile files
class PlatformFile {
  final dynamic file; // io.File for mobile, XFile or html.File for web
  final Uint8List? bytes; // For web preview
  final String name;
  final String path;

  PlatformFile({
    required this.file,
    this.bytes,
    required this.name,
    required this.path,
  });
}

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
  String? _errorMessage;
  DeliveryOption _deliveryOption = DeliveryOption.pickup;
  int _validWeeks = 1;
  List<PlatformFile> _selectedPhotos = [];
  List<Map<String, dynamic>> _items = [{}];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      _errorMessage = null;
    });

    // Add event to BLoC
    final listingBloc = BlocProvider.of<ListingBloc>(context);

    try {
      listingBloc.addEvent(CreateListingEvent(
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        deliveryOption: deliveryOptionToString(_deliveryOption),
        validWeeks: _validWeeks,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        items: _items,
        photos: _selectedPhotos.map((pf) => pf.file).toList(),
      ));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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

        for (var xFile in pickedImages) {
          if (kIsWeb) {
            // Web handling
            final bytes = await xFile.readAsBytes();
            setState(() {
              _selectedPhotos.add(PlatformFile(
                file: xFile,
                bytes: bytes,
                name: xFile.name,
                path: xFile.path,
              ));
            });
          } else {
            // Mobile handling
            setState(() {
              _selectedPhotos.add(PlatformFile(
                file: io.File(xFile.path),
                name: xFile.name,
                path: xFile.path,
              ));
            });
          }
        }
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

        if (kIsWeb) {
          // Web handling
          final bytes = await photo.readAsBytes();
          setState(() {
            _selectedPhotos.add(PlatformFile(
              file: photo,
              bytes: bytes,
              name: photo.name,
              path: photo.path,
            ));
          });
        } else {
          // Mobile handling
          setState(() {
            _selectedPhotos.add(PlatformFile(
              file: io.File(photo.path),
              name: photo.name,
              path: photo.path,
            ));
          });
        }
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

  Widget _buildPhotoPreview(PlatformFile platformFile, int index) {
    if (kIsWeb) {
      if (platformFile.bytes != null) {
        return Image.memory(
          platformFile.bytes!,
          fit: BoxFit.cover,
        );
      } else {
        // Fallback if bytes are not available
        return Center(child: Icon(Icons.image, size: 40));
      }
    } else {
      return Image.file(
        platformFile.file as io.File,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final listingBloc = BlocProvider.of<ListingBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('create_listing')),
      ),
      drawer: AppDrawer(),
      body: StreamBuilder(
        stream: listingBloc.state,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is ListingCreatedState) {
              // Navigate back on successful creation with a result to trigger refresh
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop(true); // Return true to indicate successful creation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('listing_created_successfully')),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            } else if (state is ErrorState) {
              // Show error message
              _isLoading = false;
              _errorMessage = state.message;
            } else if (state is LoadingState) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }
          }

          return _isLoading
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
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

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
                              final platformFile = _selectedPhotos[index];
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
                                      child: _buildPhotoPreview(platformFile, index),
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
                      SizedBox(height: 24),

                      // Submit
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          ),
                          child: Text(
                            localization.translate('submit'),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}