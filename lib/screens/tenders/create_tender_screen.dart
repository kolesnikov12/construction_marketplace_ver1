/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:construction_marketplace/providers/tender_provider.dart';
import 'package:construction_marketplace/providers/city_provider.dart';
import 'package:construction_marketplace/widgets/app_drawer.dart';
import 'package:construction_marketplace/widgets/tenders/tender_item_form.dart';
import 'package:construction_marketplace/utils/l10n/app_localizations.dart';

import '../../models/basic_models.dart';

class CreateTenderScreen extends StatefulWidget {
  static const routeName = '/create-tender';

  @override
  _CreateTenderScreenState createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  DeliveryOption _deliveryOption = DeliveryOption.pickup;
  int _validWeeks = 1;
  List<File> _selectedFiles = [];
  List<Map<String, dynamic>> _items = [{}]; // Start with one empty item

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid form
      return;
    }
    if (_items.isEmpty || _items.any((item) => !_isItemValid(item))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('tender_items_required'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tenderItems = _items
          .map((item) => TenderItem(
                id: '',
                // This will be assigned by the backend
                categoryId: item['categoryId'],
                subcategoryId: item['subcategoryId'],
                itemName: item['itemName'],
                manufacturer: item['manufacturer'],
                model: item['model'],
                quantity: double.parse(item['quantity']),
                unit: item['unit'],
              ))
          .toList();

      await Provider.of<TenderProvider>(context, listen: false).createTender(
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        budget: double.parse(_budgetController.text),
        deliveryOption: _deliveryOption,
        validWeeks: _validWeeks,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        items: tenderItems,
        attachments: _selectedFiles.isEmpty ? null : _selectedFiles,
      );

      // Navigate back to the tenders list screen
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
    return item['categoryId'] != null &&
        item['categoryId'].isNotEmpty &&
        item['itemName'] != null &&
        item['itemName'].isNotEmpty &&
        item['quantity'] != null &&
        item['quantity'].isNotEmpty &&
        item['unit'] != null &&
        item['unit'].isNotEmpty;
  }

  void _addItem() {
    setState(() {
      if (_items.length < 30) {
        // Maximum 30 items allowed
        _items.add({});
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        // Keep at least one item
        _items.removeAt(index);
      }
    });
  }

  void _updateItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'xlsx',
          'xls',
          'doc',
          'docx',
          'zip',
          'rar'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();

        // Check file count limit
        if (_selectedFiles.length + files.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.translate('max_5_files'))),
          );
          return;
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
        return '🗄️';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('create_tender')),
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
                        // Tender Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText:
                                localization.translate('tender_title') + ' *',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${localization.translate('item')} ${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        if (_items.length > 1)
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _removeItem(index),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TenderItemForm(
                                      item: _items[index],
                                      onUpdate: (updatedItem) =>
                                          _updateItem(index, updatedItem),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Add Item Button
                        if (_items.length < 30)
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

                        // Budget
                        TextFormField(
                          controller: _budgetController,
                          decoration: InputDecoration(
                            labelText:
                                localization.translate('budget_cad') + ' *',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return localization.translate('field_required');
                            }
                            if (double.tryParse(value) == null) {
                              return localization
                                  .translate('enter_valid_number');
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

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
                            return Provider.of<CityProvider>(context,
                                    listen: false)
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
                            labelText:
                                localization.translate('valid_for') + ' *',
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3, 4].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                  '$value ${localization.translate(value == 1 ? 'week' : 'weeks')}'),
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
                          title:
                              Text(localization.translate('delivery_required')),
                          value: DeliveryOption.delivery,
                          groupValue: _deliveryOption,
                          onChanged: (DeliveryOption? value) {
                            setState(() {
                              _deliveryOption = value!;
                            });
                          },
                        ),
                        RadioListTile<DeliveryOption>(
                          title: Text(
                              localization.translate('requires_discussion')),
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

                        // Attachments
                        Text(
                          localization.translate('attachments'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          localization.translate('max_5_files_allowed'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8),

                        // File Picker
                        if (_selectedFiles.length < 5)
                          ElevatedButton.icon(
                            icon: Icon(Icons.attach_file),
                            label: Text(localization.translate('select_files')),
                            onPressed: _pickFiles,
                          ),

                        // Selected Files List
                        if (_selectedFiles.isNotEmpty) ...[
                          SizedBox(height: 16),
                          ...List.generate(_selectedFiles.length, (index) {
                            final file = _selectedFiles[index];
                            final extension =
                                path.extension(file.path).replaceAll('.', '');

                            return ListTile(
                              leading: Text(_getFileIcon(extension),
                                  style: TextStyle(fontSize: 24)),
                              title: Text(path.basename(file.path)),
                              subtitle: Text(
                                  '${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
                              trailing: IconButton(
                                icon: Icon(Icons.clear, color: Colors.red),
                                onPressed: () => _removeFile(index),
                              ),
                            );
                          }),
                        ],

                        SizedBox(height: 32),

                        // Submit Button
                        Center(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 12),
                            ),
                            child: Text(
                              localization.translate('create_tender'),
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
*/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../bloc/bloc_provider.dart';
import '../../bloc/tender_bloc.dart';
import '../../bloc/base/bloc_events.dart';
import '../../bloc/base/bloc_states.dart';
import '../../models/enums.dart';
import '../../providers/city_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/tenders/tender_item_form.dart';
import 'package:provider/provider.dart';

class CreateTenderScreen extends StatefulWidget {
  static const routeName = '/create-tender';

  @override
  _CreateTenderScreenState createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  DeliveryOption _deliveryOption = DeliveryOption.pickup;
  int _validWeeks = 1;
  List<File> _selectedFiles = [];
  List<Map<String, dynamic>> _items = [{}]; // Start with one empty item
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty || _items.any((item) => !_isItemValid(item))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('tender_items_required')),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Add event to BLoC
    final tenderBloc = BlocProvider.of<TenderBloc>(context);
    tenderBloc.addEvent(CreateTenderEvent(
      title: _titleController.text.trim(),
      city: _cityController.text.trim(),
      budget: double.parse(_budgetController.text),
      deliveryOption: deliveryOptionToString(_deliveryOption),
      validWeeks: _validWeeks,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      items: _items,
      attachments: _selectedFiles.isEmpty ? null : _selectedFiles,
    ));
  }

  bool _isItemValid(Map<String, dynamic> item) {
    return item['categoryId'] != null &&
        item['categoryId'].isNotEmpty &&
        item['itemName'] != null &&
        item['itemName'].isNotEmpty &&
        item['quantity'] != null &&
        item['quantity'].isNotEmpty &&
        item['unit'] != null &&
        item['unit'].isNotEmpty;
  }

  void _addItem() {
    setState(() {
      if (_items.length < 30) {
        // Maximum 30 items allowed
        _items.add({});
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        // Keep at least one item
        _items.removeAt(index);
      }
    });
  }

  void _updateItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'pdf', 'xlsx', 'xls', 'doc', 'docx', 'zip', 'rar'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();

        // Check file count limit
        if (_selectedFiles.length + files.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('max_5_files')),
            ),
          );
          return;
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
        return '🗄️';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final tenderBloc = BlocProvider.of<TenderBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('create_tender')),
      ),
      drawer: AppDrawer(),
      body: StreamBuilder(
        stream: tenderBloc.state,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final state = snapshot.data;

            if (state is TenderCreatedState) {
              // Navigate back on successful creation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('tender_created_successfully')),
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

                      // Tender Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: localization.translate('tender_title') + ' *',
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

                      // Items List (same as original code)
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
                                  TenderItemForm(
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
                      if (_items.length < 30)
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

                      // Budget
                      TextFormField(
                        controller: _budgetController,
                        decoration: InputDecoration(
                          labelText: localization.translate('budget_cad') + ' *',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localization.translate('field_required');
                          }
                          if (double.tryParse(value) == null) {
                            return localization.translate('enter_valid_number');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

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
                        title: Text(localization.translate('delivery_required')),
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

                      // Attachments
                      Text(
                        localization.translate('attachments'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        localization.translate('max_5_files_allowed'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 8),

                      // File Picker
                      if (_selectedFiles.length < 5)
                        ElevatedButton.icon(
                          icon: Icon(Icons.attach_file),
                          label: Text(localization.translate('select_files')),
                          onPressed: _pickFiles,
                        ),

                      // Selected Files List
                      if (_selectedFiles.isNotEmpty) ...[
                        SizedBox(height: 16),
                        ...List.generate(_selectedFiles.length, (index) {
                          final file = _selectedFiles[index];
                          final extension = path.extension(file.path).replaceAll('.', '');

                          return ListTile(
                            leading: Text(_getFileIcon(extension), style: TextStyle(fontSize: 24)),
                            title: Text(path.basename(file.path)),
                            subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
                            trailing: IconButton(
                              icon: Icon(Icons.clear, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          );
                        }),
                      ],

                      SizedBox(height: 32),

                      // Submit Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          ),
                          child: Text(
                            localization.translate('create_tender'),
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
          );
        },
      ),
    );
  }
}