// File generated manually or via `flutterfire configure`.
// Replace placeholder values with your project credentials from Firebase Console.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
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
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDLin1-U3mHAYblWRqagdjcEpVmUkiNdrE',
    appId: '1:464583911861:web:032c451324ed822ad611fc',
    messagingSenderId: '464583911861',
    projectId: 'plantcare-kp1504',
    authDomain: 'plantcare-kp1504.firebaseapp.com',
    storageBucket: 'plantcare-kp1504.firebasestorage.app',
    measurementId: 'G-JE61YKJY5S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1D5fOQXI4UWYpwnO6cHB5B6yC2HFvENk',
    appId: '1:464583911861:android:33b885601f097461d611fc',
    messagingSenderId: '464583911861',
    projectId: 'plantcare-kp1504',
    storageBucket: 'plantcare-kp1504.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWHKevwIf07RVrU9jDS2x0GPcOiOgnDtA',
    appId: '1:464583911861:ios:16cf3623549a207ad611fc',
    messagingSenderId: '464583911861',
    projectId: 'plantcare-kp1504',
    storageBucket: 'plantcare-kp1504.firebasestorage.app',
    iosClientId: '464583911861-vp9ocpc6ufcgkprfva6in7ih65bkvrrc.apps.googleusercontent.com',
    iosBundleId: 'com.plantcare.plantcare',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDLin1-U3mHAYblWRqagdjcEpVmUkiNdrE',
    appId: '1:464583911861:web:20eb273b81ceaf51d611fc',
    messagingSenderId: '464583911861',
    projectId: 'plantcare-kp1504',
    authDomain: 'plantcare-kp1504.firebaseapp.com',
    storageBucket: 'plantcare-kp1504.firebasestorage.app',
    measurementId: 'G-1ZD7WMQWTF',
  );
}
