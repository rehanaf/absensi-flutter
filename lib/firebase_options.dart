// File generated automatically by AI based on user provided config
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDHKCASkll-vu_hInZMe2kU0QBsUR9mbuA',
    appId: '1:482635294519:web:e1af81c8085985c53a5cb2',
    messagingSenderId: '482635294519',
    projectId: 'absensi-37fe8',
    authDomain: 'absensi-37fe8.firebaseapp.com',
    storageBucket: 'absensi-37fe8.firebasestorage.app',
    measurementId: 'G-73X32ZQL8B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvEB2uVa9MJoyzo55MHQIymwaqKSbBM1E',
    appId: '1:482635294519:android:cb7f952999c75d9b3a5cb2',
    messagingSenderId: '482635294519',
    projectId: 'absensi-37fe8',
    storageBucket: 'absensi-37fe8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAyUaH8E4FJy1e2iumQxRVzpINlxSmh3ls',
    appId: '1:482635294519:ios:68de1cdbf3ddbc123a5cb2',
    messagingSenderId: '482635294519',
    projectId: 'absensi-37fe8',
    storageBucket: 'absensi-37fe8.firebasestorage.app',
    iosBundleId: 'com.reyraphael.absensi',
  );
}
