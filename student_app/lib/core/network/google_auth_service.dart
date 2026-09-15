import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mysun_app/core/network/google_config.dart';

/// Thin wrapper around the `google_sign_in` plugin. Only responsibility is
/// getting an ID token to hand to `POST /auth/google` — the actual Supabase
/// session comes back from the backend, same as email/password login.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web needs the OAuth client ID directly; native platforms use
    // `serverClientId` so the issued ID token's audience is this same web
    // client, which is what's registered with Supabase's Google provider.
    clientId: kIsWeb ? googleWebClientId : null,
    serverClientId: kIsWeb ? null : googleWebClientId,
    scopes: const ['email', 'profile'],
  );

  /// Returns the Google ID token, or `null` if the user cancelled.
  /// Throws [StateError] if sign-in succeeded but no ID token came back
  /// (shouldn't happen with the scopes above, but fail loudly if it does).
  Future<String?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }
    return idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
