# Project Structure

This document outlines the organization of the Construction Materials Marketplace Flutter application.

## Directory Structure

```
construction_marketplace/
├── assets/
│   ├── data/
│   │   └── categories_subcategories.txt
│   ├── images/
│   └── lang/
│       ├── en.json
│       └── fr.json
├── lib/
│   ├── models/
│   │   ├── user.dart
│   │   ├── category.dart
│   │   ├── tender.dart
│   │   └── listing.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── category_provider.dart
│   │   ├── city_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── tender_provider.dart
│   │   └── listing_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── tenders/
│   │   │   ├── tender_list_screen.dart
│   │   │   ├── tender_detail_screen.dart
│   │   │   ├── create_tender_screen.dart
│   │   │   └── my_tenders_screen.dart
│   │   ├── listings/
│   │   │   ├── listing_list_screen.dart
│   │   │   ├── listing_detail_screen.dart
│   │   │   ├── create_listing_screen.dart
│   │   │   └── my_listings_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── favorites/
│   │   │   └── favorites_screen.dart
│   │   └── home_screen.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   ├── app_theme.dart
│   │   └── l10n/
│   │       └── app_localizations.dart
│   ├── widgets/
│   │   ├── app_drawer.dart
│   │   ├── tenders/
│   │   │   ├── tender_list_item.dart
│   │   │   ├── tender_item_form.dart
│   │   │   └── filter_dialog.dart
│   │   └── listings/
│   │       ├── listing_grid_item.dart
│   │       ├── listing_item_form.dart
│   │       └── listing_filter_dialog.dart
│   └── main.dart
├── pubspec.yaml
├── README.md
└── PROJECT_STRUCTURE.md
```

## Core Components

### Models

Data classes that represent the core entities in the application:

- **User**: User profile information
- **Category**: Categories and subcategories for construction materials
- **Tender**: Requests for construction materials
- **Listing**: Offers to sell construction materials

### Providers

State management using the Provider pattern:

- **AuthProvider**: Handles user authentication
- **CategoryProvider**: Manages categories and subcategories
- **CityProvider**: Provides Canadian cities for filtering and selection
- **LocaleProvider**: Manages language selection (English/French)
- **TenderProvider**: Manages tender creation, listings, and operations
- **ListingProvider**: Manages listing creation, listings, and operations

### Screens

User interface screens:

- **Auth**: Login and registration screens
- **Tenders**: Browsing, creating, and managing tenders
- **Listings**: Browsing, creating, and managing listings
- **Profile**: User profile management
- **Favorites**: Saved tenders and listings
- **Home**: Main entry point with tabs for tenders and listings

### Widgets

Reusable UI components:

- **App Drawer**: Navigation drawer for the application
- **Tender Widgets**: UI components specific to tenders
- **Listing Widgets**: UI components specific to listings

### Utils

Utility classes and constants:

- **Constants**: App-wide constants and configuration
- **AppTheme**: Theme definition for the application
- **AppLocalizations**: Internationalization support

## Features

1. **Authentication**
    - User registration, login, and profile management
    - Password reset functionality

2. **Tender Management**
    - Create, view, edit, and delete tenders
    - Filter tenders by various criteria
    - Add tenders to favorites

3. **Listing Management**
    - Create, view, edit, and delete listings
    - Filter listings by various criteria
    - Add listings to favorites
    - Mark listings as sold

4. **Internationalization**
    - Support for English and French languages
    - Easy switching between languages

5. **City & Category Support**
    - Canadian cities database
    - Comprehensive category and subcategory system

## Next Steps

To complete the project implementation:

1. Implement the missing screens and widgets
2. Create a real backend API or implement mock services
3. Add proper error handling and loading states
4. Implement complete testing coverage
5. Set up CI/CD for deployment