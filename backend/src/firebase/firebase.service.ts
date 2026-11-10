import { Injectable, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import * as admin from "firebase-admin";
import { requireEmulators } from "../config/local-environment";
import { runtimeEnvironment } from "../config/runtime-environment";

@Injectable()
export class FirebaseService implements OnModuleInit, OnModuleDestroy {
  private app: admin.app.App;

  async onModuleInit() {
    const config = runtimeEnvironment();
    if (config.environment === "local") await requireEmulators(config);
    this.app = admin.initializeApp(
      {
        projectId: config.projectId,
        databaseURL: config.databaseURL,
        storageBucket: config.storageBucket,
        ...(config.serviceAccount
          ? { credential: admin.credential.cert(config.serviceAccount) }
          : {}),
      },
      "aerotrans-" + config.environment + "-" + Date.now(),
    );
    this.firestore.settings({ ignoreUndefinedProperties: true });
  }

  async onModuleDestroy() {
    if (this.app) await this.app.delete();
  }
  get firestore(): admin.firestore.Firestore {
    return admin.firestore(this.app);
  }
  get rtdb(): admin.database.Database {
    return admin.database(this.app);
  }
  get auth(): admin.auth.Auth {
    return admin.auth(this.app);
  }
  get storage(): admin.storage.Storage {
    return admin.storage(this.app);
  }
}
