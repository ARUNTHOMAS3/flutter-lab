
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDBIJNUMCCUXrz6l5NVd4W-5iVcch5s59c',
    appId: '1:105068145437:web:02a6cf1545deabe7054ff4',
    messagingSenderId: '105068145437',
    projectId: 'exp-7-aa3af',
    authDomain: 'exp-7-aa3af.firebaseapp.com',
    storageBucket: 'exp-7-aa3af.firebasestorage.app',
    measurementId: 'G-WM6WRQRSY5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXQY8J4SQ0joVouAnLGnMtz-NlAqlydh0',
    appId: '1:105068145437:android:2be72bd366e59986054ff4',
    messagingSenderId: '105068145437',
    projectId: 'exp-7-aa3af',
    storageBucket: 'exp-7-aa3af.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCPnf1fY-w34ILGLh1SiyU3xkbAtb-w3wM',
    appId: '1:105068145437:ios:f858661553ab4e97054ff4',
    messagingSenderId: '105068145437',
    projectId: 'exp-7-aa3af',
    storageBucket: 'exp-7-aa3af.firebasestorage.app',
    iosBundleId: 'com.example.exp5',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCPnf1fY-w34ILGLh1SiyU3xkbAtb-w3wM',
    appId: '1:105068145437:ios:f858661553ab4e97054ff4',
    messagingSenderId: '105068145437',
    projectId: 'exp-7-aa3af',
    storageBucket: 'exp-7-aa3af.firebasestorage.app',
    iosBundleId: 'com.example.exp5',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDBIJNUMCCUXrz6l5NVd4W-5iVcch5s59c',
    appId: '1:105068145437:web:7c639735f6bc9871054ff4',
    messagingSenderId: '105068145437',
    projectId: 'exp-7-aa3af',
    authDomain: 'exp-7-aa3af.firebaseapp.com',
    storageBucket: 'exp-7-aa3af.firebasestorage.app',
    measurementId: 'G-8RT1QD8QE9',
  );
}
