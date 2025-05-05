class StoragePaths {
  static String profileImage(String userId) => 'profile_images/$userId.jpg';
  static String tenderAttachment(String userId, String fileName) => 'tenders/$userId/$fileName';
  static String listingPhoto(String userId, String fileName) => 'listings/$userId/$fileName';
}