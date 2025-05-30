import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyChTHm5Un8yragbPCe7MWzRf1c3ckaF9xg",
    authDomain: "atoms-innovation-hub-5fbd0.firebaseapp.com",
    projectId: "atoms-innovation-hub-5fbd0",
    storageBucket: "atoms-innovation-hub-5fbd0.firebasestorage.app",
    messagingSenderId: "515741927926",
    appId: "1:515741927926:web:b82971dfa655ee81619fd7",
    measurementId: "G-9WXP4G6HKW"
  );

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(options: firebaseOptions);
  }
}

// Note: Replace the placeholder values with your actual Firebase configuration
// You can obtain these values from the Firebase console after creating a project 