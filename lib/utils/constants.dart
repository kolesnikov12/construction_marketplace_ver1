class Constants {
  // API Constants
  static const String apiBaseUrl = 'https://api.constructionmarketplace.com/v1';

  // Shared Preferences Keys
  static const String prefsUserData = 'userData';
  static const String prefsLanguage = 'language';

  // File Upload Constants
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileExtensions = [
    'jpg', 'jpeg', 'png', 'pdf', 'xlsx', 'xls', 'doc', 'docx', 'zip', 'rar'
  ];

  // Image Upload Constants
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = [
    'jpg', 'jpeg', 'png'
  ];

  // Pagination
  static const int itemsPerPage = 20;

  // Validation
  static const int maxTenderItems = 30;
  static const int maxListingItems = 20;
  static const int maxPhotos = 5;
  static const int maxFiles = 5;

  // Default Values
  static const String defaultLocale = 'en';
  static const String defaultCurrency = 'CAD';
}

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String tenders = '/tenders';
  static const String tenderDetail = '/tenders/detail';
  static const String createTender = '/tenders/create';
  static const String myTenders = '/tenders/my';
  static const String listings = '/listings';
  static const String listingDetail = '/listings/detail';
  static const String createListing = '/listings/create';
  static const String myListings = '/listings/my';
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
}