import { Request, Response, NextFunction, RequestHandler } from "express";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Handler = (req: any, res: Response, next: NextFunction) => Promise<unknown>;

export function asyncHandler(fn: Handler): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}
