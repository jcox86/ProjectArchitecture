/*
module: src.adminUi.envTypes
purpose: Provide Vite environment typing for the admin UI.
exports:
  - types: ImportMetaEnv
patterns:
  - vite_env
*/
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_ENTRA_CLIENT_ID?: string;
  readonly VITE_ENTRA_TENANT_ID?: string;
  readonly VITE_ENTRA_REDIRECT_URI?: string;
  readonly VITE_ADMIN_API_BASE_URL?: string;
  readonly VITE_ADMIN_API_SCOPE?: string;
  readonly VITE_UI_LOGGING_ENABLED?: string;
  readonly VITE_UI_LOG_LEVEL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
