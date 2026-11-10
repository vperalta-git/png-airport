import { Test } from "@nestjs/testing";
import { INestApplication } from "@nestjs/common";
import request from "supertest";
import { AppModule } from "../src/app.module";
import { FirebaseService } from "../src/firebase/firebase.service";
import { setupApplication } from "../src/app.setup";

describe("actual Nest HTTP foundation (no Firebase/cloud connection)", () => {
  let app: INestApplication;
  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(FirebaseService)
      .useValue({})
      .compile();
    app = module.createNestApplication();
    setupApplication(app);
    await app.init();
  });
  afterAll(async () => {
    await app?.close();
  });
  it("publishes a versioned local health/contract and normalized errors", async () => {
    const health = await request(app.getHttpServer())
      .get("/api/v1/health")
      .expect(200);
    expect(health.body.schemaVersion).toBe("1");
    expect(health.body.data.projectId).toBe("demo-aerotrans-png2");
    const contract = await request(app.getHttpServer())
      .get("/api/v1/contracts")
      .expect(200);
    expect(contract.body.data.roles).toContain("SUPERVISOR");
    const blocked = await request(app.getHttpServer())
      .post("/api/v1/auth/login")
      .send({ email: "x@example.invalid", password: "anything" })
      .expect(503);
    expect(blocked.body.error.code).toBe("WORKFLOW_NOT_READY");
    expect(blocked.body.data).toBeNull();
    await request(app.getHttpServer())
      .post("/api/v1/bookings")
      .send({ total_fare: 1 })
      .expect(401);
  });
});
