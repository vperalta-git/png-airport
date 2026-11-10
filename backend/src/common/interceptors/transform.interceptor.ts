import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { Observable, map } from "rxjs";
import { ApiResponse } from "@png-transfer/types";
@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    _context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => ({
        schemaVersion: "1",
        success: true as const,
        data,
        error: null,
        meta: {
          timestamp: new Date().toISOString(),
          timezone: "Pacific/Port_Moresby" as const,
          requestId: randomUUID(),
        },
      })),
    );
  }
}
