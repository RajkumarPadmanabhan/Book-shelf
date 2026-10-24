import 'package:firebase_core/firebase_core.dart';

/// Android app `shelfwise-89cdf` from android/app/google-services.json.
const shelfwiseFirebase = FirebaseOptions(
  apiKey: 'AIzaSyBurou8ZZz6zwcSngiRgc4yQF8HZxnmIkY',
  appId: '1:141186279089:android:165e571a1fb55956a76490',
  messagingSenderId: '141186279089',
  projectId: 'shelfwise-89cdf',
  storageBucket: 'shelfwise-89cdf.firebasestorage.app',
);

Future<void> ensureFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: shelfwiseFirebase);
  }
}
