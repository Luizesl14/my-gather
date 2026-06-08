export type Result<T, E> = Ok<T> | Err<E>;

export type Ok<T> = {
  ok: true;
  value: T;
};

export type Err<E> = {
  ok: false;
  error: E;
};

export const Result = {
  ok<T>(value: T): Result<T, never> {
    return { ok: true, value };
  },
  err<E>(error: E): Result<never, E> {
    return { ok: false, error };
  },
  isOk<T, E>(result: Result<T, E>): result is Ok<T> {
    return result.ok;
  },
  isErr<T, E>(result: Result<T, E>): result is Err<E> {
    return !result.ok;
  },
} as const;

