/*
module: src.adminUi.telemetry
purpose: Generate and persist correlation identifiers for UI telemetry.
exports:
  - getSessionCorrelationId
  - createRequestCorrelationId
patterns:
  - correlation_id
*/
const sessionKey = "ui.correlationId";
let requestCounter = 0;

const createRandomId = () =>
  globalThis.crypto?.randomUUID?.() ??
  `cid-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;

export const getSessionCorrelationId = (): string => {
  try {
    const existing = sessionStorage.getItem(sessionKey);
    if (existing) {
      return existing;
    }

    const created = createRandomId();
    sessionStorage.setItem(sessionKey, created);
    return created;
  } catch {
    return createRandomId();
  }
};

export const createRequestCorrelationId = (): string => {
  requestCounter += 1;
  return `${getSessionCorrelationId()}-${requestCounter}`;
};
