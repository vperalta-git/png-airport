import { NestFactory } from "@nestjs/core";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { AppModule } from "./app.module";
import { setupApplication } from "./app.setup";
export async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  setupApplication(app);
  const config = new DocumentBuilder()
    .setTitle("AeroTrans PNG2 - isolated Android demo")
    .setDescription(
      "Emulator-only four-role workflow. Explicit test rates; no live payment or tracking providers. Unconverted APIs remain unavailable.",
    )
    .setVersion("1.0.0")
    .addBearerAuth()
    .build();
  SwaggerModule.setup(
    "api/docs",
    app,
    SwaggerModule.createDocument(app, config),
  );
  await app.listen(Number(process.env.PORT || 8080), "127.0.0.1");
  return app;
}
if (require.main === module)
  bootstrap().catch((error) => {
    console.error("Local startup failed: " + error.message);
    process.exitCode = 1;
  });
