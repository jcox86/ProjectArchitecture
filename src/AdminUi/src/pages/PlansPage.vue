<!--
module: src.adminUi.pages.plans
purpose: Admin view for plans and add-ons catalog management.
exports:
  - PlansPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Plans & Add-ons"
      subtitle="Maintain subscription plans and add-ons."
    />
    <action-bar
      primary-label="New plan"
      secondary-label="New add-on"
      hint="Plans and add-ons must be active before pricing can go live."
      @primary="handleCreatePlan"
      @secondary="handleCreateAddon"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <n-grid :cols="2" x-gap="16" y-gap="16">
      <n-gi>
        <data-table-card
          title="Plans"
          :columns="planColumns"
          :data="plans"
          :loading="isLoading"
          :pagination="{ pageSize: 5 }"
        />
      </n-gi>
      <n-gi>
        <data-table-card
          title="Add-ons"
          :columns="addonColumns"
          :data="addons"
          :loading="isLoading"
          :pagination="{ pageSize: 5 }"
        />
      </n-gi>
    </n-grid>
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.plans
purpose: Provide plan and add-on data tables for the admin UI.
exports:
  - state: plans
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { AddonSummary, PlanSummary } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const plans = ref<PlanSummary[]>([]);
const addons = ref<AddonSummary[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const statusTag = (status: string) =>
  h(NTag, { type: status === "active" ? "success" : "warning" }, () => status);

const planColumns: DataTableColumns<PlanSummary> = [
  { title: "Name", key: "name" },
  {
    title: "Status",
    key: "status",
    render: (row) => statusTag(row.status)
  },
  { title: "Add-ons", key: "addons" }
];

const addonColumns: DataTableColumns<AddonSummary> = [
  { title: "Name", key: "name" },
  {
    title: "Status",
    key: "status",
    render: (row) => statusTag(row.status)
  }
];

const handleCreatePlan = () => message.info("Plan creation flow will open.");
const handleCreateAddon = () => message.info("Add-on creation flow will open.");

const loadCatalog = async () => {
  isLoading.value = true;
  error.value = null;
  const results = await Promise.allSettled([
    adminApi.listPlans(),
    adminApi.listAddons()
  ]);

  const [plansResult, addonsResult] = results;
  if (plansResult.status === "fulfilled") {
    plans.value = plansResult.value;
  } else {
    plans.value = [];
    error.value = "Failed to load plans.";
  }

  if (addonsResult.status === "fulfilled") {
    addons.value = addonsResult.value;
  } else {
    addons.value = [];
    error.value = error.value
      ? `${error.value} Failed to load add-ons.`
      : "Failed to load add-ons.";
  }

  if (error.value) {
    message.error(error.value);
  }

  isLoading.value = false;
};

onMounted(() => {
  void loadCatalog();
});
</script>
