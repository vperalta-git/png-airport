/// Batch A has one supported runtime: local emulators. Cloud activation is later work.
class AppConfig {
  static const projectId = 'demo-aerotrans-png2';
  static const environment =
      String.fromEnvironment('AEROTRANS_ENV', defaultValue: 'local');
  static const emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '127.0.0.1');
  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');
  static String apiBaseUrl =
      _overrideUrl.isEmpty ? 'http://$emulatorHost:8080' : _overrideUrl;
  static const authPort = 9099;
  static const firestorePort = 8085;
  static const databasePort = 9000;
  static const storagePort = 9199;

  static void validate() {
    if (environment != 'local') {
      throw StateError('Only local emulator mode is supported in Batch A.');
    }
    if (!['127.0.0.1', 'localhost', '10.0.2.2'].contains(emulatorHost)) {
      throw StateError(
          'EMULATOR_HOST must be loopback or the Android emulator host alias.');
    }
    normalizeUrl(apiBaseUrl);
  }

  static String normalizeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.scheme != 'http' ||
        !['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError(
          'API_BASE_URL must be a local HTTP origin without a path.');
    }
    return uri.origin;
  }
}
