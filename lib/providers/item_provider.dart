import 'package:flutter/material.dart';
import 'package:construction_marketplace/providers/category_provider.dart';

/// Provider for item suggestions and common operations
class ItemProvider with ChangeNotifier {
  // In a real app, this would fetch data from an API or database
  // For now, we'll use static data for demo purposes
  final Map<String, List<String>> _itemSuggestionsByCategory = {
    // Building Materials
    'Building Materials': [
      '2x4 Pressure Treated Lumber',
      '2x6 Pressure Treated Lumber',
      '4x8 Plywood Sheets',
      'OSB Sheathing',
      'Drywall Sheets',
      'Insulation Batts',
      'Concrete Mix',
      'Cement Blocks',
      'Roofing Shingles',
      'Metal Roofing',
    ],

    // Tools
    'Tools': [
      'Cordless Drill',
      'Circular Saw',
      'Hammer',
      'Screwdriver Set',
      'Measuring Tape',
      'Level',
      'Tool Box',
      'Work Bench',
      'Air Compressor',
      'Nail Gun',
    ],

    // Electrical
    'Electrical': [
      'Electrical Wire',
      'Electrical Boxes',
      'Circuit Breakers',
      'Electrical Panel',
      'Light Switches',
      'Electrical Outlets',
      'Conduit',
      'Junction Boxes',
      'Wire Connectors',
      'Surge Protectors',
    ],

    // Plumbing
    'Plumbing': [
      'PVC Pipes',
      'Copper Pipes',
      'Pipe Fittings',
      'Valves',
      'Faucets',
      'Sink Drains',
      'P-Traps',
      'Water Heater',
      'Toilet',
      'Bathroom Sink',
    ],

    // Flooring
    'Floors & Area Rugs': [
      'Hardwood Flooring',
      'Laminate Flooring',
      'Vinyl Flooring',
      'Ceramic Tiles',
      'Carpet',
      'Area Rug',
      'Floor Underlayment',
      'Grout',
      'Tile Spacers',
      'Transition Strips',
    ],

    // Paint
    'Paint': [
      'Interior Paint',
      'Exterior Paint',
      'Primer',
      'Paint Rollers',
      'Paint Brushes',
      'Paint Tray',
      'Paint Sprayer',
      'Painter\'s Tape',
      'Drop Cloths',
      'Paint Thinner',
    ],

    // Kitchen
    'Kitchen': [
      'Kitchen Cabinets',
      'Kitchen Countertops',
      'Kitchen Sink',
      'Kitchen Faucet',
      'Backsplash Tile',
      'Range Hood',
      'Refrigerator',
      'Stove',
      'Dishwasher',
      'Microwave',
    ],

    // Bath
    'Bath': [
      'Bathroom Vanity',
      'Bathroom Sink',
      'Bathroom Faucet',
      'Bathroom Mirror',
      'Shower Head',
      'Shower Enclosure',
      'Bathtub',
      'Toilet',
      'Towel Rack',
      'Bathroom Fan',
    ],

    // Hardware
    'Hardware': [
      'Door Knobs',
      'Cabinet Handles',
      'Hinges',
      'Screws',
      'Nails',
      'Bolts',
      'Anchors',
      'Door Stops',
      'Corner Braces',
      'Picture Hangers',
    ],

    // Doors & Windows
    'Doors & Windows': [
      'Interior Door',
      'Exterior Door',
      'Sliding Patio Door',
      'French Door',
      'Single-Hung Window',
      'Double-Hung Window',
      'Casement Window',
      'Awning Window',
      'Window Screen',
      'Window Blinds',
    ],

    // Appliances
    'Appliances': [
      'Refrigerator',
      'Range',
      'Dishwasher',
      'Microwave',
      'Washer',
      'Dryer',
      'Freezer',
      'Range Hood',
      'Garbage Disposal',
      'Wine Cooler',
    ]
  };

  // Subcategory suggestions
  final Map<String, List<String>> _itemSuggestionsBySubcategory = {
    // Building Materials subcategories
    'Lumber & Composites': [
      '2x4 Pressure Treated Lumber',
      '2x6 Pressure Treated Lumber',
      '4x4 Cedar Post',
      '1x6 Cedar Decking',
      'Plywood Sheets',
      'OSB Sheathing',
      'Particle Board',
      'MDF Board',
    ],

    // Tools subcategories
    'Power Tools': [
      'Cordless Drill',
      'Circular Saw',
      'Jigsaw',
      'Reciprocating Saw',
      'Angle Grinder',
      'Router',
      'Belt Sander',
      'Compound Miter Saw',
    ],

    'Hand Tools': [
      'Hammer',
      'Screwdriver Set',
      'Wrench Set',
      'Pliers',
      'Measuring Tape',
      'Level',
      'Square',
      'Utility Knife',
    ],

    // Kitchen subcategories
    'Kitchen Cabinets': [
      'Base Cabinet',
      'Wall Cabinet',
      'Pantry Cabinet',
      'Kitchen Island',
      'Cabinet Doors',
      'Drawer Fronts',
      'Cabinet Organizers',
      'Soft Close Hinges',
    ],

    'Kitchen Sinks': [
      'Single Bowl Sink',
      'Double Bowl Sink',
      'Farmhouse Sink',
      'Bar Sink',
      'Stainless Steel Sink',
      'Composite Sink',
      'Cast Iron Sink',
      'Sink Strainer',
    ],

    // Flooring subcategories
    'Hardwood Flooring': [
      'Oak Hardwood',
      'Maple Hardwood',
      'Cherry Hardwood',
      'Hickory Hardwood',
      'Bamboo Flooring',
      'Engineered Hardwood',
      'Hardwood Transition Strips',
      'Hardwood Floor Cleaner',
    ],

    'Laminate Flooring': [
      'Wood Look Laminate',
      'Stone Look Laminate',
      'Water Resistant Laminate',
      'Laminate Underlayment',
      'Laminate Transition Strips',
      'Laminate Floor Cleaner',
      'Laminate Installation Kit',
      'Laminate Repair Kit',
    ],
  };

  /// Get item suggestions based on search pattern, category, and subcategory
  Future<List<String>> getSuggestions(String pattern, String categoryId, String? subcategoryId) async {
    // In a real app, this would call an API
    // For demo, we'll return filtered static data
    await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay

    List<String> suggestions = [];

    if (subcategoryId != null && _itemSuggestionsBySubcategory.containsKey(subcategoryId)) {
      suggestions = _itemSuggestionsBySubcategory[subcategoryId]!;
    } else if (_itemSuggestionsByCategory.containsKey(categoryId)) {
      suggestions = _itemSuggestionsByCategory[categoryId]!;
    } else {
      // Fallback to all items if category not found
      suggestions = _getAllItemSuggestions();
    }

    if (pattern.isEmpty) {
      return suggestions.take(10).toList(); // Limit to 10 suggestions when no pattern
    }

    pattern = pattern.toLowerCase();
    return suggestions
        .where((item) => item.toLowerCase().contains(pattern))
        .toList();
  }

  /// Get all item suggestions (flattened list)
  List<String> _getAllItemSuggestions() {
    Set<String> allItems = {};

    _itemSuggestionsByCategory.values.forEach((items) {
      allItems.addAll(items);
    });

    _itemSuggestionsBySubcategory.values.forEach((items) {
      allItems.addAll(items);
    });

    return allItems.toList();
  }

  /// Get common units for a specific item
  String getDefaultUnitForItem(String itemName) {
    // In a real app, this would be retrieved from a database
    // For demo, use some basic logic
    final itemNameLower = itemName.toLowerCase();

    if (itemNameLower.contains('lumber') || itemNameLower.contains('board')) {
      return 'pcs';
    } else if (itemNameLower.contains('flooring') || itemNameLower.contains('tile')) {
      return 'sq.m';
    } else if (itemNameLower.contains('pipe') || itemNameLower.contains('conduit')) {
      return 'm';
    } else if (itemNameLower.contains('concrete') || itemNameLower.contains('sand')) {
      return 'cubic m';
    } else if (itemNameLower.contains('paint')) {
      return 'liter';
    }

    return 'pcs'; // Default unit
  }
}