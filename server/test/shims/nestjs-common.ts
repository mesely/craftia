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
