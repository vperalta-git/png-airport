import { ExecutionContext } from "@nestjs/common";
import { FirebaseAuthGuard } from "./auth.guard";
import { FirebaseService } from "../../firebase/firebase.service";
const context = (headers: Record<string, string>) =>
  ({
    switchToHttp: () => ({ getRequest: () => ({ headers }) }),
  }) as ExecutionContext;
describe("canonical guard has no implicit development identity", () => {
  it("rejects missing tokens and forged developer/worker identity headers", async () => {
    const guard = new FirebaseAuthGuard({} as FirebaseService);
    for (const headers of [
      {},
      { "x-dev-role": "SUPER_ADMIN" },
      { "x-internal-worker-token": "old-demo-secret" },
    ]) {
      await expect(guard.canActivate(context(headers))).rejects.toThrow(
        "Firebase ID token is required",
      );
    }
  });
  it("does not default missing role or tenant scope from a profile", async () => {
    const guard = new FirebaseAuthGuard({
      auth: { verifyIdToken: async () => ({ uid: "user" }) },
    } as unknown as FirebaseService);
    await expect(
      guard.canActivate(context({ authorization: "Bearer token" })),
    ).rejects.toThrow("incompletely scoped");
  });
});
