<!--
module: src.adminUi.pages.pricing
purpose: Admin view for plan and add-on pricing.
exports:
  - PricingPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Pricing"
      subtitle="Define plan pricing across intervals and currencies."
    />
    <action-bar
      primary-label="Add price"
      secondary-label="Sync Stripe"
      hint="Pricing changes are synced with Stripe metadata."
      @primary="handleAddPrice"
      @secondary="handleSync"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Plan prices"
      :columns="columns"
      :data="prices"
      :loading="isLoading"
      :pagination="{ pageSize: 6 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.pricing
purpose: Provide pricing data table configuration.
exports:
  - state: prices
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { PlanPrice } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const prices = ref<PlanPrice[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<PlanPrice> = [
  { title: "Plan", key: "planId" },
  { title: "Interval", key: "interval" },
  {
    title: "Amount",
    key: "amount",
    render: (row) => `${row.currency} ${row.amount}`
  },
  {
    title: "Status",
    key: "status",
    render: (row) =>
      h(
        NTag,
        { type: row.status === "active" ? "success" : "warning" },
        () => row.status
      )
  }
];

const handleAddPrice = () => message.info("Pricing editor will open.");
const handleSync = () => {
  void loadPrices(true);
};

const loadPrices = async (notify?: boolean) => {
  isLoading.value = true;
  error.value = null;
  try {
    prices.value = await adminApi.listPrices();
    if (notify) {
      message.success("Pricing refreshed.");
    }
  } catch (loadError) {
    const messageText =
      loadError instanceof Error ? loadError.message : "Failed to load pricing.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  void loadPrices();
});
</script>
