import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/config/app_config.dart';

void main() {
  void validate(
          {String project = AppConfig.stagingProjectId,
          String platform = 'android',
          String appId = '1:123:android:testfixture',
          String sender = '123',
          String key = 'public-test-placeholder'}) =>
      AppConfig.validateHostedFirebase(
          project: project,
          platform: platform,
          apiKey: key,
          appId: appId,
          senderId: sender,
          authDomain: '${AppConfig.stagingProjectId}.firebaseapp.com');
  test('registered Android and web test identities remain distinct', () {
    validate();
    validate(platform: 'web', appId: '1:123:web:testfixture');
    expect(() => validate(appId: '1:123:web:testfixture'), throwsStateError);
    expect(() => validate(platform: 'web'), throwsStateError);
  });
  test(
      'native config rejects live projects, unsupported platforms and incomplete credentials',
      () {
    expect(() => validate(project: 'airport-png-c866b'), throwsStateError);
    expect(() => validate(platform: 'ios'), throwsStateError);
    expect(() => validate(sender: 'wrong'), throwsStateError);
    expect(() => validate(key: ''), throwsStateError);
    expect(
        () => validate(key: '-----BEGIN PRIVATE KEY-----'), throwsStateError);
    expect(() => validate(appId: '1:123:android:'), throwsStateError);
  });
}
