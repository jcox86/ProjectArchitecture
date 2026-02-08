/*
module: src.adminUi.telemetry
purpose: Sanitize UI log payloads to avoid leaking sensitive data.
exports:
  - sanitizeText
  - sanitizeError
patterns:
  - pii_redaction
*/
const maxTextLength = 512;
const maxStackLength = 2048;

const jwtPattern = /[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+/g;
const bearerPattern = /Bearer\s+[A-Za-z0-9-_.]+/gi;
const emailPattern = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const credentialPattern = /(api[_-]?key|token|secret|password)=([^&\s]+)/gi;

const redactSecrets = (value: string): string =>
  value
    .replace(bearerPattern, "Bearer [REDACTED]")
    .replace(jwtPattern, "[REDACTED_JWT]")
    .replace(emailPattern, "[REDACTED_EMAIL]")
    .replace(credentialPattern, "$1=[REDACTED]");

const trimTo = (value: string, max: number): string =>
  value.length > max ? `${value.slice(0, max)}…` : value;

export const sanitizeText = (value?: string): string | undefined => {
  if (!value) {
    return undefined;
  }

  const normalized = value.replace(/\s+/g, " ").trim();
  return trimTo(redactSecrets(normalized), maxTextLength);
};

export const sanitizeError = (error: unknown) => {
  if (!error || typeof error !== "object") {
    return undefined;
  }

  const err = error as { name?: string; message?: string; stack?: string };
  return {
    name: sanitizeText(err.name),
    message: sanitizeText(err.message),
    stack: err.stack ? trimTo(redactSecrets(err.stack), maxStackLength) : undefined
  };
};
