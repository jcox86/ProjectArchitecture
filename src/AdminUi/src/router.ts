/*
module: src.adminUi.router
purpose: Configure SPA routes for admin sections.
exports:
  - router
patterns:
  - vue_router
*/
import { createRouter, createWebHistory } from "vue-router";
const TenantsPage = () => import("./pages/TenantsPage.vue");
const FlagsPage = () => import("./pages/FlagsPage.vue");
const PlansPage = () => import("./pages/PlansPage.vue");
const PricingPage = () => import("./pages/PricingPage.vue");
const BillingPage = () => import("./pages/BillingPage.vue");
const AnnouncementsPage = () => import("./pages/AnnouncementsPage.vue");
const JobsPage = () => import("./pages/JobsPage.vue");
const AuditPage = () => import("./pages/AuditPage.vue");

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", redirect: "/tenants" },
    { path: "/tenants", component: TenantsPage },
    { path: "/flags", component: FlagsPage },
    { path: "/plans", component: PlansPage },
    { path: "/pricing", component: PricingPage },
    { path: "/billing", component: BillingPage },
    { path: "/announcements", component: AnnouncementsPage },
    { path: "/jobs", component: JobsPage },
    { path: "/audit", component: AuditPage }
  ]
});
