export type LoggerContext = Record<string, unknown>;

export interface Logger {
  info(context: LoggerContext, message: string): void;
  warn(context: LoggerContext, message: string): void;
  error(context: LoggerContext, message: string): void;
}

export class ConsoleLogger implements Logger {
  info(context: LoggerContext, message: string): void {
    console.log(JSON.stringify({ level: "info", message, ...context }));
  }

  warn(context: LoggerContext, message: string): void {
    console.warn(JSON.stringify({ level: "warn", message, ...context }));
  }

  error(context: LoggerContext, message: string): void {
    console.error(JSON.stringify({ level: "error", message, ...context }));
  }
}

export const logger: Logger = new ConsoleLogger();

