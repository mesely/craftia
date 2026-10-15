/**
 * Nest 12 ships as ESM, which Jest (CommonJS) cannot load on Node 20. The unit tests only need the
 * decorators to be no-ops and the exception classes to exist, so they are shimmed here.
 */
const noop = () => () => undefined;
export const Injectable = noop;
export const Optional = noop;
export const Global = noop;
export const Module = noop;

class HttpError extends Error {
  constructor(message?: string) {
    super(message);
    this.name = new.target.name;
  }
}
export class BadRequestException extends HttpError {}
export class ForbiddenException extends HttpError {}
export class NotFoundException extends HttpError {}
export class PayloadTooLargeException extends HttpError {}
export class ConflictException extends HttpError {}
export class UnauthorizedException extends HttpError {}
export class HttpException extends HttpError {
  constructor(message?: string, readonly status?: number) {
    super(message);
  }
}
export const HttpStatus = { TOO_MANY_REQUESTS: 429, PAYMENT_REQUIRED: 402 };
export class Logger {
  constructor(readonly context?: string) {}
  warn(): void {}
  log(): void {}
}
export const CanActivate = undefined;
export class ServiceUnavailableException extends HttpError {}
