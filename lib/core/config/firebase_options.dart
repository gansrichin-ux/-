import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseOptions {
  AppFirebaseOptions._();

  static const apiKey = 'AIzaSyAB-VmodBzw8eoRiTqrs9kDRKZTY3hqsHE';
  static const appId = '1:222919916416:web:6fc7344f07bb9778635f65';
  static const messagingSenderId = '222919916416';
  static const projectId = 'logist-app-55ac9';
  static const authDomain = 'logist-app-55ac9.firebaseapp.com';
  static const storageBucket = 'logist-app-55ac9.firebasestorage.app';

  static const currentPlatform = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    if (kIsWeb) {
      await Firebase.initializeApp(options: currentPlatform);
      return;
    }

    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      if (error.code == 'core/not-initialized' ||
          error.code == 'not-found' ||
          error.code == 'invalid-app-argument') {
        await Firebase.initializeApp(options: currentPlatform);
        return;
      }
      rethrow;
    }
  }
}
