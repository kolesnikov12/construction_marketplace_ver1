import 'package:cloud_firestore/cloud_firestore.dart';

String handleFirebaseError(dynamic error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'The requested document was not found';
      case 'already-exists':
        return 'The document already exists';
      case 'resource-exhausted':
        return 'You have exceeded your quota. Please try again later';
      case 'invalid-argument':
        return 'Invalid argument provided';
      case 'unavailable':
        return 'Service unavailable. Please check your connection and try again';
      case 'unauthenticated':
        return 'You need to be logged in to perform this action';
      default:
        return error.message ?? 'An unknown error occurred';
    }
  }

  return error.toString();
}

// Example Firestore document schemas:

/*
// User document schema
{
  "id": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1 (123) 456-7890",
  "profileImageUrl": "https://firebasestorage.googleapis.com/...",
  "fcmToken": "token123",
  "createdAt": Timestamp,
  "lastLoginAt": Timestamp,
  "isEmailVerified": true,
  "preferences": {
    "language": "en",
    "notifications": true
  },
  "savedAddressIds": ["address1", "address2"],
  "favoriteTenders": ["tender1", "tender2"],
  "favoriteListings": ["listing1", "listing2"]
}

// Tender document schema
{
  "userId": "user123",
  "title": "Need Quality Lumber for Home Renovation",
  "description": "Looking for premium quality lumber for a complete home renovation project. Need various sizes and types.",
  "city": "Toronto, ON",
  "budget": 2500.00,
  "deliveryOption": "pickup",
  "validUntil": Timestamp,
  "status": "open",
  "createdAt": Timestamp,
  "items": [
    {
      "id": "item1",
      "categoryId": "Building Materials",
      "subcategoryId": "Lumber & Composites",
      "itemName": "2x4 Pressure Treated Lumber",
      "manufacturer": null,
      "model": null,
      "quantity": 50,
      "unit": "pcs"
    }
  ],
  "attachmentUrls": [
    "https://firebasestorage.googleapis.com/..."
  ],
  "bidders": ["user456", "user789"]
}

// Listing document schema
{
  "userId": "user123",
  "title": "Premium Hardwood Flooring - Clearance Sale",
  "description": "Leftover premium oak hardwood flooring from a completed project. In excellent condition.",
  "city": "Toronto, ON",
  "deliveryOption": "pickup",
  "validUntil": Timestamp,
  "status": "available",
  "createdAt": Timestamp,
  "items": [
    {
      "id": "item1",
      "categoryId": "Floors & Area Rugs",
      "subcategoryId": "Hardwood Flooring",
      "itemName": "Oak Hardwood Flooring",
      "manufacturer": "Bruce",
      "model": "Natural Reflections",
      "quantity": 75,
      "unit": "sq.m",
      "price": 35.00,
      "isFree": false
    }
  ],
  "photoUrls": [
    "https://firebasestorage.googleapis.com/..."
  ]
}

// Bid document schema
{
  "tenderId": "tender123",
  "userId": "user456",
  "amount": 2200.00,
  "message": "I can provide all the lumber you need at this price.",
  "status": "pending", // pending, accepted, rejected
  "createdAt": Timestamp
}

// Message document schema
{
  "senderId": "user123",
  "recipientId": "user456",
  "content": "Hi, I'm interested in your listing.",
  "createdAt": Timestamp,
  "read": false,
  "relatedItemId": "listing789", // Optional reference to a tender or listing
  "relatedItemType": "listing" // "tender" or "listing"
}
*/