/*
module: src.adminUi.api.client
purpose: Provide a thin API client wrapper with auth headers and correlation IDs.
exports:
  - adminApiClient
patterns:
  - fetch_wrapper
  - correlation_headers
*/
import { appConfig } from "../appConfig";
import { useAuth } from "../auth/useAuth";
import { createRequestCorrelationId } from "../telemetry/correlation";

const buildUrl = (path: string) => {
  const normalized = path.startsWith("/") ? path : `/${path}`;
  return `${appConfig.adminApiBaseUrl}${normalized}`;
};

const request = async <T>(path: string, init?: RequestInit): Promise<T> => {
  const auth = useAuth();
  const accessToken = await auth.getAccessToken();

  if (!accessToken) {
    throw new Error("Missing access token.");
  }

  const response = await fetch(buildUrl(path), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      "X-Correlation-ID": createRequestCorrelationId(),
      ...(init?.headers ?? {})
    }
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(message || `Request failed: ${response.status}`);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
};

export const adminApiClient = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "POST",
      body: body ? JSON.stringify(body) : undefined
    }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "PUT",
      body: body ? JSON.stringify(body) : undefined
    })
};
