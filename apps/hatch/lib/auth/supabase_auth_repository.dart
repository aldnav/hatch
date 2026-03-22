import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hatch/auth/auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Nonce helpers for Apple Sign-In
// ---------------------------------------------------------------------------

/// Generates a cryptographically random nonce of [length] characters.
String _generateNonce([int length = 32]) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
  final random = Random.secure();
  return List<String>.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

/// Returns the SHA-256 hex digest of [input].
String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Supabase-backed implementation of [AuthRepository].
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  // -------------------------------------------------------------------------
  // Magic link
  // -------------------------------------------------------------------------

  @override
  Future<void> signInWithMagicLink(String email) =>
      _client.auth.signInWithOtp(
        email: email,
        // On web GoTrue uses SITE_URL (localhost:3000) as the redirect target.
        // On mobile the hatch:// deep link is used instead.
        emailRedirectTo: kIsWeb ? null : 'hatch://auth/callback',
      );

  // -------------------------------------------------------------------------
  // Google Sign-In
  // -------------------------------------------------------------------------

  @override
  Future<void> signInWithGoogle() async {
    // Web and desktop: browser-based OAuth via Supabase.
    // Requires Google OAuth provider configured in GoTrue (see issue #11).
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }

    // Android / iOS: native picker → ID token exchange.
    // Requires google-services.json (Android) / GoogleService-Info.plist (iOS).
    final googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  // -------------------------------------------------------------------------
  // Apple Sign-In
  // -------------------------------------------------------------------------

  @override
  Future<void> signInWithApple() async {
    // Android: browser-based OAuth (Apple has no native Android SDK).
    // Requires Apple Service ID configured in Apple Developer Portal.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'hatch://auth/callback',
      );
      return;
    }

    // Web: browser-based OAuth.
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.apple);
      return;
    }

    // iOS / macOS: native credential + nonce exchange.
    // Requires "Sign In with Apple" capability in Xcode (see issue #12).
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: rawNonce,
    );
  }

  // -------------------------------------------------------------------------
  // Sign out
  // -------------------------------------------------------------------------

  @override
  Future<void> signOut() => _client.auth.signOut();
}
