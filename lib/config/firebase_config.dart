import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

/*
 * Here are the Firestore security rules you should use for this project.
 * You can copy and paste these into the Firebase Console -> Firestore Database -> Rules tab.
 */

/*
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles - only the user can write to their own profile
    match /users/{userId} {
      allow read: if true; // Allow all users to read profiles
      allow create: if request.auth != null; // Allow authenticated users to create profiles
      allow update, delete: if request.auth != null && request.auth.uid == userId; // Only owner can update/delete
    }

    // Tenders - can be read by anyone, but only created/updated by authenticated users
    match /tenders/{tenderId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        (resource.data.userId == request.auth.uid || request.resource.data.userId == request.auth.uid);
    }

    // Listings - can be read by anyone, but only created/updated by authenticated users
    match /listings/{listingId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        (resource.data.userId == request.auth.uid || request.resource.data.userId == request.auth.uid);
    }

    // Bids on tenders - can be read by the tender owner and the bidder
    match /bids/{bidId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         get(/databases/$(database)/documents/tenders/$(resource.data.tenderId)).data.userId == request.auth.uid);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Messages between users
    match /messages/{messageId} {
      allow read: if request.auth != null &&
        (resource.data.senderId == request.auth.uid || resource.data.recipientId == request.auth.uid);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.senderId == request.auth.uid;
    }
  }
}
*/