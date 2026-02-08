<!--
module: src.adminUi.pages.announcements
purpose: Admin view for managing announcement lifecycle.
exports:
  - AnnouncementsPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Announcements"
      subtitle="Publish maintenance, feature, and incident announcements."
    />
    <action-bar
      primary-label="New announcement"
      secondary-label="Schedule publish"
      hint="Announcements can be scoped globally or by tenant override."
      @primary="handleCreate"
      @secondary="handleSchedule"
    />
    <n-alert v-if="error" type="error" :show-icon="false">
      {{ error }}
    </n-alert>
    <data-table-card
      title="Announcement queue"
      :columns="columns"
      :data="announcements"
      :loading="isLoading"
      :pagination="{ pageSize: 6 }"
    />
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.announcements
purpose: Provide announcement data for the admin UI.
exports:
  - state: announcements
patterns:
  - vue_script_setup
*/
import { h, onMounted, ref } from "vue";
import { NAlert, NTag, useMessage, type DataTableColumns } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { AnnouncementSummary } from "../api/types";
import ActionBar from "../components/ActionBar.vue";
import DataTableCard from "../components/DataTableCard.vue";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();

const announcements = ref<AnnouncementSummary[]>([]);
const isLoading = ref(false);
const error = ref<string | null>(null);

const columns: DataTableColumns<AnnouncementSummary> = [
  { title: "Title", key: "title" },
  { title: "Type", key: "type" },
  {
    title: "Status",
    key: "status",
    render: (row) =>
      h(
        NTag,
        {
          type:
            row.status === "published"
              ? "success"
              : row.status === "scheduled"
              ? "warning"
              : "default"
        },
        () => row.status
      )
  },
  { title: "Audience", key: "audience" }
];

const handleCreate = () => message.info("Announcement editor will open.");
const handleSchedule = () => message.success("Schedule workflow will open.");

const loadAnnouncements = async () => {
  isLoading.value = true;
  error.value = null;
  try {
    announcements.value = await adminApi.listAnnouncements();
  } catch (loadError) {
    const messageText =
      loadError instanceof Error
        ? loadError.message
        : "Failed to load announcements.";
    error.value = messageText;
    message.error(messageText);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  void loadAnnouncements();
});
</script>
