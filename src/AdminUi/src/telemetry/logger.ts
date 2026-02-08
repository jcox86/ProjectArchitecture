/*
module: src.adminUi.telemetry
purpose: Capture safe client logs, enrich with context, and ship to the admin API.
exports:
  - initUiLogging
  - uiLogger
  - setTelemetryContext
patterns:
  - safe_logging
  - telemetry_batching
*/
import { appConfig } from "../appConfig";
import { useAuth } from "../auth/useAuth";
import { createRequestCorrelationId, getSessionCorrelationId } from "./correlation";
import { sanitizeError, sanitizeText } from "./sanitize";
import type { UiLogEvent, UiLogLevel } from "./types";

type TelemetryContext = {
  tenantId?: string;
  component?: string;
};

const buffer: UiLogEvent[] = [];
const maxBufferSize = 200;
const maxBatchSize = 20;
const flushIntervalMs = 5000;
let flushTimer: number | undefined;

const getUserId = () => {
  const auth = useAuth();
  const account = auth.account.value;
  return account?.homeAccountId ?? account?.localAccountId ?? undefined;
};

const getTenantId = () => {
  const auth = useAuth();
  const account = auth.account.value;
  return account?.tenantId ?? undefined;
};

const isLoggingEnabled = () => appConfig.uiLoggingEnabled;

const shouldShipLevel = (level: UiLogLevel) => {
  const target = appConfig.uiLogLevel;
  const order: UiLogLevel[] = ["debug", "info", "warn", "error"];
  return order.indexOf(level) >= order.indexOf(target);
};

const context: TelemetryContext = {};

export const setTelemetryContext = (next: TelemetryContext) => {
  context.tenantId = next.tenantId ?? context.tenantId;
  context.component = next.component ?? context.component;
};

const sanitizeContext = (input?: Record<string, string>) => {
  if (!input) {
    return undefined;
  }

  const sanitizedEntries = Object.entries(input)
    .map(([key, value]) => [key, sanitizeText(value)])
    .filter(([, value]) => !!value) as Array<[string, string]>;

  return sanitizedEntries.length ? Object.fromEntries(sanitizedEntries) : undefined;
};

const buildEvent = (
  level: UiLogLevel,
  message: string,
  options?: { error?: unknown; context?: Record<string, string>; component?: string }
): UiLogEvent => ({
  level,
  message: sanitizeText(message) ?? "Unknown UI log message.",
  timestamp: new Date().toISOString(),
  correlationId: getSessionCorrelationId(),
  userId: getUserId(),
  tenantId: context.tenantId ?? getTenantId(),
  route: window.location.pathname,
  component: options?.component ?? context.component,
  context: sanitizeContext(options?.context),
  error: sanitizeError(options?.error)
});

const enqueue = (event: UiLogEvent) => {
  if (buffer.length >= maxBufferSize) {
    buffer.shift();
  }

  buffer.push(event);
};

const shipLogs = async (events: UiLogEvent[]) => {
  if (!events.length) {
    return;
  }

  const auth = useAuth();
  const accessToken = await auth.getAccessToken();
  if (!accessToken) {
    return;
  }

  const correlationId = createRequestCorrelationId();
  const response = await fetch(`${appConfig.adminApiBaseUrl}/telemetry/logs`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      "X-Correlation-ID": correlationId
    },
    body: JSON.stringify({ logs: events }),
    keepalive: true
  });

  if (!response.ok) {
    // Avoid infinite loops by only logging to console here.
     
    console.warn("Failed to ship UI logs.", await response.text());
  }
};

const flush = async () => {
  if (!buffer.length) {
    return;
  }

  const batch = buffer.splice(0, maxBatchSize);
  try {
    await shipLogs(batch);
  } catch (error) {
     
    console.warn("UI telemetry flush failed.", error);
  }
};

const scheduleFlush = () => {
  if (flushTimer || !isLoggingEnabled()) {
    return;
  }

  flushTimer = window.setInterval(() => {
    void flush();
  }, flushIntervalMs);
};

const log = (
  level: UiLogLevel,
  message: string,
  options?: { error?: unknown; context?: Record<string, string>; component?: string }
) => {
  if (!isLoggingEnabled() || !shouldShipLevel(level)) {
    return;
  }

  const event = buildEvent(level, message, options);
  enqueue(event);

  if (level === "error" || buffer.length >= maxBatchSize) {
    void flush();
  }
};

export const uiLogger = {
  debug: (message: string, options?: { context?: Record<string, string>; component?: string }) =>
    log("debug", message, options),
  info: (message: string, options?: { context?: Record<string, string>; component?: string }) =>
    log("info", message, options),
  warn: (message: string, options?: { error?: unknown; context?: Record<string, string>; component?: string }) =>
    log("warn", message, options),
  error: (message: string, options?: { error?: unknown; context?: Record<string, string>; component?: string }) =>
    log("error", message, options)
};

export const initUiLogging = () => {
  if (!isLoggingEnabled()) {
    return;
  }

  scheduleFlush();

  window.addEventListener("error", (event) => {
    uiLogger.error("Unhandled UI error.", {
      error: event.error ?? event.message,
      context: { source: "window.onerror" }
    });
  });

  window.addEventListener("unhandledrejection", (event) => {
    uiLogger.error("Unhandled promise rejection.", {
      error: event.reason,
      context: { source: "window.onunhandledrejection" }
    });
  });
};
