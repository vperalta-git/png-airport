import { INestApplication, ValidationPipe } from "@nestjs/common";
import { GlobalHttpExceptionFilter } from "./common/filters/http-exception.filter";
import { TransformInterceptor } from "./common/interceptors/transform.interceptor";
import { runtimeOrigins } from "./config/runtime-environment";
export function setupApplication(app: INestApplication) {
  app.setGlobalPrefix("api/v1");
  const origins = runtimeOrigins();
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
