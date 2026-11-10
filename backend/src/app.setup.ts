import { INestApplication, ValidationPipe } from "@nestjs/common";
import { GlobalHttpExceptionFilter } from "./common/filters/http-exception.filter";
import { TransformInterceptor } from "./common/interceptors/transform.interceptor";
export function setupApplication(app: INestApplication) {
  app.setGlobalPrefix("api/v1");
  const allowed = [5001, 5002, 5003, 5004].flatMap((port) => [
    "http://localhost:" + port,
    "http://127.0.0.1:" + port,
  ]);
  const origins =
    process.env.ALLOWED_ORIGINS?.split(",").map((value) => value.trim()) ??
    allowed;
  if (origins.some((origin) => !allowed.includes(origin)))
    throw new Error(
      "ALLOWED_ORIGINS must contain only the fixed local Flutter origins.",
    );
  app.enableCors({ origin: origins, credentials: false });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new GlobalHttpExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());
}
