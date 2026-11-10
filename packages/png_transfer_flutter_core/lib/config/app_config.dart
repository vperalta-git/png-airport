/// Local emulators and the separately approved, isolated hosted test project.
class AppConfig {
  static const localProjectId = 'demo-aerotrans-png2';
  static const stagingProjectId = 'aerotrans-png-test-7d7128';
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID',
      defaultValue: localProjectId);
  static const environment =
      String.fromEnvironment('AEROTRANS_ENV', defaultValue: 'local');
  static const emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '127.0.0.1');
  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');
  static const hostedTest = environment == 'staging';
  static const firebaseClientPlatform =
      String.fromEnvironment('FIREBASE_CLIENT_PLATFORM', defaultValue: 'web');
  static const firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const firebaseAndroidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const firebaseWebApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const firebaseWebAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const firebaseSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseApiKey = firebaseClientPlatform == 'android'
      ? firebaseAndroidApiKey
      : firebaseWebApiKey;
  static const firebaseAppId = firebaseClientPlatform == 'android'
      ? firebaseAndroidAppId
      : firebaseWebAppId;
  static String apiBaseUrl =
      _overrideUrl.isEmpty ? 'http://$emulatorHost:8080' : _overrideUrl;
  static const authPort = 9099;
  static const firestorePort = 8085;
  static const databasePort = 9000;
  static const storagePort = 9199;

  /// A hosted visitor's localhost is not the operator's review computer.
  static bool allowsLocalWebServices(Uri page) =>
      ['http', 'https'].contains(page.scheme) &&
      ['127.0.0.1', 'localhost', '10.0.2.2'].contains(page.host);

  static void validate() {
    if (hostedTest) {
      validateHostedFirebase(
          project: projectId,
          platform: firebaseClientPlatform,
          apiKey: firebaseApiKey,
          appId: firebaseAppId,
          senderId: firebaseSenderId,
          authDomain: firebaseAuthDomain);
      normalizeUrl(apiBaseUrl);
      return;
    }
    if (environment != 'local' || projectId != localProjectId) {
      throw StateError(
          'Only local emulators or the approved hosted test project are supported.');
    }
    if (!['127.0.0.1', 'localhost', '10.0.2.2'].contains(emulatorHost)) {
      throw StateError(
          'EMULATOR_HOST must be loopback or the Android emulator host alias.');
    }
    normalizeUrl(apiBaseUrl);
  }

  static void validateHostedFirebase(
      {required String project,
      required String platform,
      required String apiKey,
      required String appId,
      required String senderId,
      required String authDomain}) {
    if (project != stagingProjectId ||
        !['web', 'android'].contains(platform) ||
        apiKey.isEmpty ||
        apiKey.contains('PRIVATE KEY') ||
        !RegExp(r'^\d+$').hasMatch(senderId) ||
        !appId.startsWith('1:$senderId:$platform:') ||
        appId.split(':').last.isEmpty ||
        (platform == 'web' &&
            authDomain != '$stagingProjectId.firebaseapp.com')) {
      throw StateError(
          'Complete platform-specific Firebase configuration for the approved test project is required.');
    }
  }

  static String normalizeUrl(String url) =>
      normalizeRuntimeUrl(url, environment, projectId);

  static String normalizeRuntimeUrl(
      String url, String runtime, String firebaseProject) {
    final uri = Uri.tryParse(url.trim());
    final staging = runtime == 'staging' && firebaseProject == stagingProjectId;
    final local = runtime == 'local' && firebaseProject == localProjectId;
    if (uri == null ||
        (!staging && !local) ||
        (staging
            ? uri.scheme != 'https' ||
                uri.host.isEmpty ||
                ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host)
            : uri.scheme != 'http' ||
                !['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host)) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError(
          'API_BASE_URL must be a permitted origin without a path, credentials or query.');
    }
    return uri.origin;
  }
}
