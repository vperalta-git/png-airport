import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { Request, Response } from "express";
@Catch()
export class GlobalHttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalHttpExceptionFilter.name);
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp(),
      response = ctx.getResponse<Response>(),
      request = ctx.getRequest<Request>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const body =
      exception instanceof HttpException ? exception.getResponse() : null;
    const info =
      body && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const messages = info.message;
    const message =
      status >= 500 && status !== 503
        ? "Internal server error"
        : typeof body === "string"
          ? body
          : Array.isArray(messages)
            ? messages.join("; ")
            : typeof messages === "string"
              ? messages
              : "Request failed";
    if (status >= 500)
      this.logger.error(
        "HTTP " + status + " " + request.method + " " + request.path,
      );
    response.status(status).json({
      schemaVersion: "1",
      success: false,
      data: null,
      error: {
        code:
          typeof info.code === "string"
            ? info.code
            : status === 400
              ? "VALIDATION_ERROR"
              : "HTTP_" + status,
        message,
        ...(Array.isArray(messages) ? { details: messages } : {}),
      },
      meta: {
        timestamp: new Date().toISOString(),
        timezone: "Pacific/Port_Moresby",
        requestId: randomUUID(),
      },
    });
  }
}
