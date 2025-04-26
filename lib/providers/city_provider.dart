import 'package:flutter/material.dart';

class CityProvider with ChangeNotifier {
  // This would typically be loaded from a database or API
  // For now, we're using a simple in-memory list of Canadian cities
  final List<String> _canadianCities = [
    'Toronto, ON',
    'Montreal, QC',
    'Vancouver, BC',
    'Calgary, AB',
    'Edmonton, AB',
    'Ottawa, ON',
    'Winnipeg, MB',
    'Quebec City, QC',
    'Hamilton, ON',
    'Kitchener, ON',
    'London, ON',
    'Victoria, BC',
    'Halifax, NS',
    'Oshawa, ON',
    'Windsor, ON',
    'Saskatoon, SK',
    'Regina, SK',
    'St. John\'s, NL',
    'Barrie, ON',
    'Kelowna, BC',
    'Abbotsford, BC',
    'Sherbrooke, QC',
    'Trois-Rivieres, QC',
    'Guelph, ON',
    'Moncton, NB',
    'Saint John, NB',
    'Thunder Bay, ON',
    'Sudbury, ON',
    'Chicoutimi, QC',
    'Kingston, ON',
    'Fredericton, NB',
    'Red Deer, AB',
    'Lethbridge, AB',
    'Kamloops, BC',
    'Prince George, BC',
    'Medicine Hat, AB',
    'Drummondville, QC',
    'Charlottetown, PE',
    'Belleville, ON',
    'Chatham-Kent, ON',
    'Saint-Hyacinthe, QC',
    'North Bay, ON',
    'Timmins, ON',
    'Sault Ste. Marie, ON',
    'Granby, QC',
    'Fort McMurray, AB',
    'Whitehorse, YT',
    'Yellowknife, NT',
    'Iqaluit, NU',
  ];

  // Get city suggestions based on search pattern
  Future<List<String>> getSuggestions(String pattern) async {
    // In a real application, this would query a database or API
    if (pattern.isEmpty) return [];

    // Filter by pattern
    return _canadianCities
        .where((city) => city.toLowerCase().contains(pattern.toLowerCase()))
        .toList();
  }

  // Get all Canadian cities
  List<String> getAllCities() {
    return [..._canadianCities];
  }
}