/*
module: src.adminUi.appConfig
purpose: Centralize runtime configuration sourced from Vite environment variables.
exports:
  - appConfig
  - isEntraConfigured
patterns:
  - config_centralization
*/
import type { UiLogLevel } from "./telemetry/types";

const env = import.meta.env;
const logLevel = (env.VITE_UI_LOG_LEVEL ?? "info").toLowerCase();
const allowedLogLevels: UiLogLevel[] = ["debug", "info", "warn", "error"];
const resolveLogLevel = (value: string): UiLogLevel =>
  allowedLogLevels.includes(value as UiLogLevel) ? (value as UiLogLevel) : "info";

export const appConfig = {
  adminApiBaseUrl: (env.VITE_ADMIN_API_BASE_URL ?? "/api/admin").replace(/\/$/, ""),
  adminApiScope: env.VITE_ADMIN_API_SCOPE ?? "",
  adminApiScopes: env.VITE_ADMIN_API_SCOPE ? [env.VITE_ADMIN_API_SCOPE] : [],
  entraClientId: env.VITE_ENTRA_CLIENT_ID ?? "",
  entraTenantId: env.VITE_ENTRA_TENANT_ID ?? "",
  entraRedirectUri: env.VITE_ENTRA_REDIRECT_URI ?? window.location.origin,
  uiLoggingEnabled: (env.VITE_UI_LOGGING_ENABLED ?? "true").toLowerCase() === "true",
  uiLogLevel: resolveLogLevel(logLevel)
};

export const isEntraConfigured =
  appConfig.entraClientId.length > 0 && appConfig.entraTenantId.length > 0;
