/*
module: src.adminUi.appConfig
purpose: Centralize runtime configuration sourced from Vite environment variables.
exports:
  - appConfig
  - isEntraConfigured
patterns:
  - config_centralization
*/
const env = import.meta.env;

export const appConfig = {
  adminApiBaseUrl: (env.VITE_ADMIN_API_BASE_URL ?? "/api/admin").replace(/\/$/, ""),
  adminApiScope: env.VITE_ADMIN_API_SCOPE ?? "",
  adminApiScopes: env.VITE_ADMIN_API_SCOPE ? [env.VITE_ADMIN_API_SCOPE] : [],
  entraClientId: env.VITE_ENTRA_CLIENT_ID ?? "",
  entraTenantId: env.VITE_ENTRA_TENANT_ID ?? "",
  entraRedirectUri: env.VITE_ENTRA_REDIRECT_URI ?? window.location.origin
};

export const isEntraConfigured =
  appConfig.entraClientId.length > 0 && appConfig.entraTenantId.length > 0;
