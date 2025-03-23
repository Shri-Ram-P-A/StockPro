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
    apiKey: 'AIzaSyA8VOfR7omDf8y65zsChM4GNhnlVl43xN8',
    appId: '1:480258244634:web:efa651c5b464dccb1811a3',
    messagingSenderId: '480258244634',
    projectId: 'login-67c1d',
    authDomain: 'login-67c1d.firebaseapp.com',
    storageBucket: 'login-67c1d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAwFj1dC-z5u1zkbp2g0Rz1lQug8QZjimg',
    appId: '1:480258244634:android:243a1aa4c1f97a941811a3',
    messagingSenderId: '480258244634',
    projectId: 'login-67c1d',
    storageBucket: 'login-67c1d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIe_L7Aags4EHUvUcAfQfL4I51PdM1JuM',
    appId: '1:480258244634:ios:677287cdbf3b3a421811a3',
    messagingSenderId: '480258244634',
    projectId: 'login-67c1d',
    storageBucket: 'login-67c1d.firebasestorage.app',
    iosBundleId: 'com.example.login',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCIe_L7Aags4EHUvUcAfQfL4I51PdM1JuM',
    appId: '1:480258244634:ios:677287cdbf3b3a421811a3',
    messagingSenderId: '480258244634',
    projectId: 'login-67c1d',
    storageBucket: 'login-67c1d.firebasestorage.app',
    iosBundleId: 'com.example.login',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA8VOfR7omDf8y65zsChM4GNhnlVl43xN8',
    appId: '1:480258244634:web:d2697f3ba8423b801811a3',
    messagingSenderId: '480258244634',
    projectId: 'login-67c1d',
    authDomain: 'login-67c1d.firebaseapp.com',
    storageBucket: 'login-67c1d.firebasestorage.app',
  );
}
