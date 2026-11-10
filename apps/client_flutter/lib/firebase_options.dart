// Local-only options. All Firebase SDKs must be initialized by runLocalFoundation.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart' show LocalFirebase;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => LocalFirebase.options;
}
