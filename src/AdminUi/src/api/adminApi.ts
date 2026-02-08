/*
module: src.adminUi.api.adminApi
purpose: Define typed admin API endpoints for the admin UI.
exports:
  - adminApi
patterns:
  - api_client
*/
import { adminApiClient } from "./client";
import type {
  AddonSummary,
  AnnouncementSummary,
  AuditRecord,
  BillingSummary,
  FeatureFlag,
  JobRequest,
  PlanPrice,
  PlanSummary,
  TenantSummary
} from "./types";

export const adminApi = {
  listTenants: () => adminApiClient.get<TenantSummary[]>("/tenants"),
  listFlags: () => adminApiClient.get<FeatureFlag[]>("/flags"),
  listPlans: () => adminApiClient.get<PlanSummary[]>("/billing/plans"),
  listAddons: () => adminApiClient.get<AddonSummary[]>("/billing/addons"),
  listPrices: () => adminApiClient.get<PlanPrice[]>("/billing/prices"),
  listBillingStatus: () =>
    adminApiClient.get<BillingSummary[]>("/billing/status"),
  listAnnouncements: () =>
    adminApiClient.get<AnnouncementSummary[]>("/announcements"),
  listAuditLogs: () => adminApiClient.get<AuditRecord[]>("/audit/logs"),
  enqueueJob: (job: JobRequest) =>
    adminApiClient.post<void>("/jobs/dispatch", job)
};
