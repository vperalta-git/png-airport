import { NestFactory } from "@nestjs/core";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { AppModule } from "./app.module";
import { setupApplication } from "./app.setup";
import { runtimeIdentity } from "./config/runtime-environment";
export async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  setupApplication(app);
  const config = new DocumentBuilder()
    .setTitle("AeroTrans PNG2 - isolated review API")
    .setDescription(
      "Isolated local or hosted test workflow. Explicit test rates; no live payment or tracking providers. Unconverted APIs remain unavailable.",
    )
    .setVersion("1.0.0")
    .addBearerAuth()
    .build();
  SwaggerModule.setup(
    "api/docs",
    app,
    SwaggerModule.createDocument(app, config),
  );
  await app.listen(
    Number(process.env.PORT || 8080),
    runtimeIdentity().environment === "local" ? "127.0.0.1" : "0.0.0.0",
  );
  return app;
}
bootstrap().catch((error) => {
  console.error("API startup failed: " + error.message);
  process.exitCode = 1;
});
