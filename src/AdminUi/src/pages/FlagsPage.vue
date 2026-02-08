<!--
module: src.adminUi.pages.flags
purpose: Admin view for feature flag management.
exports:
  - FlagsPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Feature Flags"
      subtitle="Control global and tenant-scoped feature flags."
    />
    <action-bar
      primary-label="Create flag"
      secondary-label="Reload flags"
      hint="Flags are cached in Redis and refreshed on change."
      @primary="handleCreate"
      @secondary="handleReload"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Flag registry"
      :columns="columns"
      :data="flags"
      :loading="isLoading"
      :pagination="{ pageSize: 7 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.flags
purpose: Provide flag data and actions for the admin UI.
exports:
  - state: flags
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { FeatureFlag } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const flags = ref<FeatureFlag[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<FeatureFlag> = [
  { title: "Key", key: "key" },
  { title: "Scope", key: "scope" },
  {
    title: "Status",
    key: "status",
    render: (row) =>
      h(
        NTag,
        { type: row.status === "enabled" ? "success" : "warning" },
        { default: () => row.status }
      )
  },
  { title: "Description", key: "description" }
];

const handleCreate = () => message.info("Flag creation flow will open.");
const handleReload = () => {
  void loadFlags(true);
};

const loadFlags = async (notify?: boolean) => {
  isLoading.value = true;
  error.value = null;
  try {
    flags.value = await adminApi.listFlags();
    if (notify) {
      message.success("Flag registry refreshed.");
    }
  } catch (loadError) {
    const messageText =
      loadError instanceof Error ? loadError.message : "Failed to load flags.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  void loadFlags();
});
</script>
