/// App-wide constants.
abstract final class AppConstants {
  static const String appName = 'MySun';
  static const String university = 'Soroti University';

  /// Set per build with `--dart-define=API_BASE_URL=https://.../api/v1`.
  /// Defaults to the local backend (`uvicorn app.main:app`) for development;
  /// on a USB-connected Android device run `adb reverse tcp:8000 tcp:8000`
  /// first. Release builds refuse to start without it (see `main.dart`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
  static const bool hasExplicitApiBaseUrl = bool.hasEnvironment('API_BASE_URL');

  /// Simulated latency for the `Mock*Repository` classes (used by
  /// `test/smoke_test.dart` to stay network-free — see `providers/repositories.dart`
  /// for the real Http* wiring the app runs on).
  static const Duration mockLatency = Duration(milliseconds: 450);

  static const int pageSize = 20;
}
