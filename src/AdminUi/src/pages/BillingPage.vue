<!--
module: src.adminUi.pages.billing
purpose: Admin view for tenant billing status and payment health.
exports:
  - BillingPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Billing Status"
      subtitle="Monitor subscriptions, payment status, and last invoice activity."
    />
    <action-bar
      primary-label="Retry invoices"
      secondary-label="Export report"
      hint="Use reports for finance reconciliation and outreach."
      @primary="handleRetry"
      @secondary="handleExport"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Tenant billing overview"
      :columns="columns"
      :data="billing"
      :loading="isLoading"
      :pagination="{ pageSize: 6 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.billing
purpose: Provide billing table data for the admin UI.
exports:
  - state: billing
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { BillingSummary } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const billing = ref<BillingSummary[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<BillingSummary> = [
  { title: "Tenant", key: "tenantName" },
  {
    title: "Subscription",
    key: "subscriptionStatus",
    render: (row) =>
      h(
        NTag,
        {
          type: row.subscriptionStatus === "active" ? "success" : "warning"
        },
        () => row.subscriptionStatus
      )
  },
  {
    title: "Payment",
    key: "paymentStatus",
    render: (row) =>
      h(
        NTag,
        { type: row.paymentStatus === "paid" ? "success" : "error" },
        () => row.paymentStatus
      )
  },
  { title: "Last invoice", key: "lastInvoice" }
];

const handleRetry = () => message.info("Retry jobs will be scheduled.");
const handleExport = () => message.success("Billing report export queued.");

const loadBilling = async () => {
  isLoading.value = true;
  error.value = null;
  try {
    billing.value = await adminApi.listBillingStatus();
  } catch (loadError) {
    const messageText =
      loadError instanceof Error
        ? loadError.message
        : "Failed to load billing status.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  void loadBilling();
});
</script>
