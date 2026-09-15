/// Fill this in once you've created an OAuth 2.0 **Web application** client
/// in Google Cloud Console (console.cloud.google.com/apis/credentials) and
/// enabled the Google provider in the Supabase dashboard with that same
/// Client ID. See backend/README.md § "Google Sign-In setup" for the full
/// walkthrough. Used on every platform — web via [GoogleSignIn.clientId],
/// Android via [GoogleSignIn.serverClientId] (so the ID token's audience
/// matches what Supabase expects regardless of platform).
const String googleWebClientId =
    'REPLACE_ME.apps.googleusercontent.com';
