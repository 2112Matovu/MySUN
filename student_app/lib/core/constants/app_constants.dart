/// App-wide constants.
abstract final class AppConstants {
  static const String appName = 'MySun';
  static const String university = 'Soroti University';

  /// Local FastAPI backend (`backend/`, run with `uvicorn app.main:app`).
  /// Works as-is for Chrome/Desktop (same machine). For a physical Android
  /// device over USB, run `adb reverse tcp:8000 tcp:8000` first so the
  /// device's own `127.0.0.1:8000` reaches this machine's backend.
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Simulated latency for the `Mock*Repository` classes (used by
  /// `test/smoke_test.dart` to stay network-free — see `providers/repositories.dart`
  /// for the real Http* wiring the app runs on).
  static const Duration mockLatency = Duration(milliseconds: 450);

  static const int pageSize = 20;
}
