<!--
module: src.adminUi.pages.tenants
purpose: Admin view for tenant lifecycle and routing status.
exports:
  - TenantsPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Tenants"
      subtitle="Manage tenant provisioning, routing, and database tiers."
    />
    <n-grid :cols="3" x-gap="16">
      <n-gi>
        <stat-card label="Active tenants" :value="activeCount" />
      </n-gi>
      <n-gi>
        <stat-card label="Provisioning" :value="provisioningCount" />
      </n-gi>
      <n-gi>
        <stat-card label="Isolated tier" :value="isolatedCount" />
      </n-gi>
    </n-grid>
    <action-bar
      primary-label="Create tenant"
      secondary-label="Refresh catalog"
      hint="Sync tenant routes and provisioning status."
      @primary="handleCreateTenant"
      @secondary="handleRefresh"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Tenant catalog"
      :columns="columns"
      :data="tenants"
      :loading="isLoading"
      :pagination="{ pageSize: 6 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.tenants
purpose: Provide tenant overview data and table configuration.
exports:
  - state: tenants
patterns:
  - vue_script_setup
*/
import { computed, h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { TenantSummary } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";
import StatCard from "../components/StatCard.vue";

const message = useMessage();

const tenants = ref<TenantSummary[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<TenantSummary> = [
  { title: "Tenant", key: "name" },
  { title: "Tier", key: "tier" },
  {
    title: "Status",
    key: "status",
    render: (row) =>
      h(
        NTag,
        { type: row.status === "active" ? "success" : "warning" },
        { default: () => row.status }
      )
  },
  {
    title: "Route",
    key: "routeStatus",
    render: (row) =>
      h(
        NTag,
        { type: row.routeStatus === "ready" ? "success" : "warning" },
        { default: () => row.routeStatus }
      )
  },
  {
    title: "Database",
    key: "databaseStatus",
    render: (row) =>
      h(
        NTag,
        { type: row.databaseStatus === "ready" ? "success" : "warning" },
        { default: () => row.databaseStatus }
      )
  }
];

const activeCount = computed(
  () => tenants.value.filter((tenant) => tenant.status === "active").length
);
const provisioningCount = computed(
  () => tenants.value.filter((tenant) => tenant.status === "provisioning").length
);
const isolatedCount = computed(
  () => tenants.value.filter((tenant) => tenant.tier === "isolated").length
);

const loadTenants = async (notify?: boolean) => {
  isLoading.value = true;
  error.value = null;
  try {
    tenants.value = await adminApi.listTenants();
    if (notify) {
      message.success("Tenant catalog refreshed.");
    }
  } catch (loadError) {
    const messageText =
      loadError instanceof Error ? loadError.message : "Failed to load tenants.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

const handleCreateTenant = () =>
  message.info("Tenant creation workflow will open.");
const handleRefresh = () => {
  void loadTenants(true);
};

onMounted(() => {
  void loadTenants();
});
</script>
