import { Injectable, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import * as admin from "firebase-admin";
import {
  localEnvironment,
  requireEmulators,
} from "../config/local-environment";

@Injectable()
export class FirebaseService implements OnModuleInit, OnModuleDestroy {
  private app: admin.app.App;

  async onModuleInit() {
    const config = localEnvironment();
    await requireEmulators(config);
    // Never initialize with ADC or a service account for this local-only batch.
    // Auth/Firestore/RTDB/Storage SDKs all honor the validated emulator variables.
    this.app = admin.initializeApp(
      {
        projectId: config.projectId,
        databaseURL: config.databaseURL,
        storageBucket: config.storageBucket,
      },
      "aerotrans-local-" + Date.now(),
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
