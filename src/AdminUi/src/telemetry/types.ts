/*
module: src.adminUi.telemetry
purpose: Define the schema for client-side log events shipped to the API.
exports:
  - type: UiLogEvent
  - type: UiLogLevel
patterns:
  - telemetry_schema
*/
export type UiLogLevel = "debug" | "info" | "warn" | "error";

export type UiLogEvent = {
  level: UiLogLevel;
  message: string;
  timestamp: string;
  correlationId: string;
  userId?: string;
  tenantId?: string;
  route?: string;
  component?: string;
  context?: Record<string, string>;
  error?: {
    name?: string;
    message?: string;
    stack?: string;
  };
};
