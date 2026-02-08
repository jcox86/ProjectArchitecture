/*
module: src.adminUi.api.types
purpose: Define shared data shapes for admin API responses.
exports:
  - type: TenantSummary
  - type: FeatureFlag
  - type: PlanSummary
  - type: PlanPrice
  - type: BillingSummary
  - type: AnnouncementSummary
  - type: JobRequest
  - type: AuditRecord
patterns:
  - typed_contracts
*/
export type TenantSummary = {
  id: string;
  name: string;
  tier: "shared" | "isolated";
  status: "active" | "suspended" | "provisioning";
  routeStatus: "ready" | "pending" | "blocked";
  databaseStatus: "ready" | "provisioning" | "error";
};

export type FeatureFlag = {
  key: string;
  scope: "global" | "tenant";
  status: "enabled" | "disabled";
  description: string;
};

export type PlanSummary = {
  id: string;
  name: string;
  status: "active" | "archived";
  addons: number;
};

export type AddonSummary = {
  id: string;
  name: string;
  status: "active" | "archived";
};

export type PlanPrice = {
  planId: string;
  interval: "monthly" | "yearly";
  amount: number;
  currency: string;
  status: "active" | "draft";
};

export type BillingSummary = {
  tenantName: string;
  subscriptionStatus: "active" | "past_due" | "canceled";
  paymentStatus: "paid" | "unpaid" | "refunded";
  lastInvoice: string;
};

export type AnnouncementSummary = {
  id: string;
  title: string;
  type: "maintenance" | "feature" | "incident";
  status: "draft" | "scheduled" | "published";
  audience: "all" | "tenant_override";
};

export type JobRequest = {
  queue: string;
  payload: string;
};

export type AuditRecord = {
  id: string;
  actor: string;
  action: string;
  subject: string;
  occurredAt: string;
  severity: "info" | "warning" | "critical";
};
