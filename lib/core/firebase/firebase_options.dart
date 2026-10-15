import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

/// Public identifiers of the Firebase project craftia-7608b (the same values ship inside every
/// app's google-services files; they are not secrets). Access is controlled by Firebase
/// Authentication rules and the server's token check, not by hiding these.
class UstaFirebase {
  const UstaFirebase._();

  static const projectId = 'craftia-7608b';

  /// Web OAuth client: Google sign-in on Android asks for an ID token for this audience.
  static const webClientId =
      '550965794228-chaa7akvh4hu9dnlisfk25e5k359cinj.apps.googleusercontent.com';

  /// iOS OAuth client (Google sign-in on iPhone).
  static const iosClientId =
      '550965794228-ana3p9j0s07g49r00vpjpd6eqic6ahsi.apps.googleusercontent.com';

  static FirebaseOptions get current => Platform.isIOS ? ios : android;

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyD8aP3OwmNVKEPDOzEWgxAlX3cpR6moO2A',
    appId: '1:550965794228:ios:7270b44fc9164276fc4ee1',
    messagingSenderId: '550965794228',
    projectId: projectId,
    storageBucket: 'craftia-7608b.firebasestorage.app',
    iosBundleId: 'com.usta.usta',
    iosClientId: iosClientId,
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDyTuHYia3tbfb8J4iR0HrFlPcJEXoNVdM',
    appId: '1:550965794228:android:927f3dbe6b3729ccfc4ee1',
    messagingSenderId: '550965794228',
    projectId: projectId,
    storageBucket: 'craftia-7608b.firebasestorage.app',
  );
}
