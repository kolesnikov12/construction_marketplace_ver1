import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:construction_marketplace/models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoaded = false;

  CategoryProvider() {
    _loadCategories();
  }

  List<Category> get categories {
    return [..._categories];
  }

  Future<void> _loadCategories() async {
    if (_isLoaded) return;

    try {
      // Load from the embedded text file
      final String categoriesData = await rootBundle.loadString('assets/data/categories_subcategories.txt');

      final List<Category> loadedCategories = [];
      Category? currentCategory;

      // Parse the text file
      final lines = LineSplitter.split(categoriesData);

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        if (!line.startsWith('*')) {
          // This is a main category
          currentCategory = Category(
            id: line.trim(), // Use name as ID for simplicity
            nameEn: line.trim(),
            nameFr: _getFrenchlName(line.trim()), // This would be replaced with proper translations
            subcategories: [],
          );
          loadedCategories.add(currentCategory);
        } else if (currentCategory != null) {
          // This is a subcategory
          final subcategoryName = line.substring(1).trim();

          final subcategory = Category(
            id: '${currentCategory.id}_$subcategoryName',
            nameEn: subcategoryName,
            nameFr: _getFrenchlName(subcategoryName), // This would be replaced with proper translations
            parentId: currentCategory.id,
          );

          currentCategory.subcategories?.add(subcategory);
        }
      }

      _categories = loadedCategories;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // This is a placeholder for proper translations
  String _getFrenchlName(String englishName) {
    // In a real application, you would use a proper translation table
    // This is just a simple example to simulate French names
    final translations = {
      'Appliances': 'Appareils électroménagers',
      'Refrigerators': 'Réfrigérateurs',
      'Freezers': 'Congélateurs',
      'Ranges & Stoves': 'Cuisinières',
      'Wall Ovens': 'Fours encastrés',
      'Cooktops': 'Tables de cuisson',
      'Range Hoods': 'Hottes de cuisine',
      'Dishwashers': 'Lave-vaisselle',
      'Microwaves': 'Micro-ondes',
      'Washers': 'Laveuses',
      'Dryers': 'Sécheuses',
      'Small Appliances': 'Petits électroménagers',
      'Vacuums & Floor Care': 'Aspirateurs et entretien des sols',

      'Bath': 'Salle de bain',
      'Bathtubs': 'Baignoires',
      'Showers & Shower Doors': 'Douches et portes de douche',
      'Toilets & Bidets': 'Toilettes et bidets',
      'Bathroom Vanities': 'Meubles-lavabos',
      'Bathroom Sinks': 'Lavabos de salle de bain',
      'Bathroom Faucets': 'Robinets de salle de bain',

      'BBQs & Outdoor Cooking': 'BBQ et cuisine en plein air',
      'Natural Gas BBQs': 'BBQ au gaz naturel',
      'Propane BBQs': 'BBQ au propane',
      'Charcoal & Pellet BBQs': 'BBQ au charbon et aux granules',

      'Building Materials': 'Matériaux de construction',
      'Lumber & Composites': 'Bois et matériaux composites',
      'Drywall': 'Cloisons sèches',
      'Concrete, Cement & Masonry': 'Béton, ciment et maçonnerie',
      'Insulation': 'Isolation',
      'Roofing & Gutters': 'Toiture et gouttières',

      'Doors & Windows': 'Portes et fenêtres',
      'Interior Doors': 'Portes intérieures',
      'Exterior Doors': 'Portes extérieures',
      'Windows': 'Fenêtres',

      'Electrical': 'Électricité',
      'Wire & Cable': 'Fils et câbles',
      'Switches, Dimmers & Outlets': 'Interrupteurs, gradateurs et prises',

      'Floors & Area Rugs': 'Planchers et tapis',
      'Hardwood Flooring': 'Planchers de bois franc',
      'Laminate Flooring': 'Planchers stratifiés',
      'Vinyl Flooring': 'Planchers de vinyle',
      'Tile Flooring': 'Carrelage',
      'Carpet & Carpet Tiles': 'Tapis et carreaux de tapis',

      'Kitchen': 'Cuisine',
      'Kitchen Cabinets': 'Armoires de cuisine',
      'Countertops & Backsplashes': 'Comptoirs et dosseret',
      'Kitchen Sinks': 'Éviers de cuisine',
      'Kitchen Faucets': 'Robinets de cuisine',

      'Paint': 'Peinture',
      'Interior Paint': 'Peinture intérieure',
      'Exterior Paint': 'Peinture extérieure',
      'Primers': 'Apprêts',
      'Wood Stains & Finishes': 'Teintures et finitions pour bois',

      'Plumbing': 'Plomberie',
      'Pipes & Fittings': 'Tuyaux et raccords',
      'Water Heaters': 'Chauffe-eau',
      'Water Filtration & Softeners': 'Filtration et adoucisseurs d\'eau',

      'Tools': 'Outils',
      'Power Tools': 'Outils électriques',
      'Hand Tools': 'Outils à main',
      'Air Tools & Compressors': 'Outils pneumatiques et compresseurs',
      'Tool Storage & Work Benches': 'Rangement d\'outils et établis',
      'Ladders & Scaffolding': 'Échelles et échafaudages',
    };

    return translations[englishName] ?? englishName;
  }

  Category? getCategoryById(String id) {
    for (var category in _categories) {
      if (category.id == id) return category;

      if (category.subcategories != null) {
        for (var subcategory in category.subcategories!) {
          if (subcategory.id == id) return subcategory;
        }
      }
    }
    return null;
  }

  List<Category> getSubcategories(String categoryId) {
    final category = _categories.firstWhere(
          (category) => category.id == categoryId,
      orElse: () => Category(id: '', nameEn: '', nameFr: ''),
    );

    return category.subcategories ?? [];
  }

  String getCategoryName(String categoryId, bool isEnglish) {
    final category = getCategoryById(categoryId);
    if (category == null) return '';

    return isEnglish ? category.nameEn : category.nameFr;
  }
}