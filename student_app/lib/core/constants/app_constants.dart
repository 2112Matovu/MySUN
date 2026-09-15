/// App-wide constants. [apiBaseUrl] is unused while the app runs on mock data;
/// it's the switch point when the FastAPI backend comes online (spec §5.3).
abstract final class AppConstants {
  static const String appName = 'MySun';
  static const String university = 'Soroti University';

  /// Local FastAPI backend (`backend/`, run with `uvicorn app.main:app`).
  /// Works as-is for Chrome/Desktop (same machine). For a physical Android
  /// device over USB, run `adb reverse tcp:8000 tcp:8000` first so the
  /// device's own `127.0.0.1:8000` reaches this machine's backend.
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Simulated latency for the mock repositories, so loading states are real.
  static const Duration mockLatency = Duration(milliseconds: 450);

  static const int pageSize = 20;
}
