import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_boot.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/common.dart';

const _serverClientId = '141186279089-if8jbplpe8te6to703g85rlqbma92u9a.apps.googleusercontent.com';

bool _googleReady = false;
Future<String?>? _inFlight;

Future<void> _ensureSignIn() async {
  await ensureFirebase();
  if (_googleReady) return;
  await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
  _googleReady = true;
}

/// Opens the device Google account sheet and returns the address the person picks.
///
/// Android only reveals an account after that person taps it. Cancel returns null.
Future<String?> signInWithDeviceGoogle() {
  final running = _inFlight;
  if (running != null) return running;
  final run = _signIn();
  _inFlight = run;
  return run.whenComplete(() => _inFlight = null);
}

Future<String?> _signIn() async {
  try {
    await _ensureSignIn();
    // Sign out first so Change shows every account on the phone, not only the last one.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    final account = await GoogleSignIn.instance.authenticate();
    final email = account.email.trim();
    if (email.isEmpty) return null;

    final token = account.authentication.idToken;
    if (token != null && token.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: token));
      } on FirebaseAuthException catch (e) {
        toast(e.message ?? 'Google account found, but Firebase rejected the sign-in');
      }
    }
    return email;
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    toast(e.description ?? 'Could not open the Google accounts on this phone');
    return null;
  }
}
