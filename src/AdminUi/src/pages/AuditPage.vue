<!--
module: src.adminUi.pages.audit
purpose: Admin view for reviewing audit logs and reports.
exports:
  - AuditPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Audit Logs"
      subtitle="Review admin actions, system events, and report exports."
    />
    <action-bar
      primary-label="Run report"
      secondary-label="Export logs"
      hint="Audit exports are stored in Blob Storage and tracked in the catalog."
      @primary="handleRunReport"
      @secondary="handleExport"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Recent activity"
      :columns="columns"
      :data="auditLogs"
      :loading="isLoading"
      :pagination="{ pageSize: 7 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.audit
purpose: Provide audit log data for the admin UI.
exports:
  - state: auditLogs
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { AuditRecord } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const auditLogs = ref<AuditRecord[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<AuditRecord> = [
  { title: "Actor", key: "actor" },
  { title: "Action", key: "action" },
  { title: "Subject", key: "subject" },
  { title: "Occurred", key: "occurredAt" },
  {
    title: "Severity",
    key: "severity",
    render: (row) =>
      h(
        NTag,
        {
          type:
            row.severity === "critical"
              ? "error"
              : row.severity === "warning"
              ? "warning"
              : "info"
        },
        () => row.severity
      )
  }
];

const handleRunReport = () => message.info("Audit report will be generated.");
const handleExport = () => message.success("Audit export queued.");

const loadAuditLogs = async () => {
  isLoading.value = true;
  error.value = null;
  try {
    auditLogs.value = await adminApi.listAuditLogs();
  } catch (loadError) {
    const messageText =
      loadError instanceof Error
        ? loadError.message
        : "Failed to load audit logs.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  void loadAuditLogs();
});
</script>
