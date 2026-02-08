<!--
module: src.adminUi.pages.jobs
purpose: Admin view for kicking off worker jobs and queue processing.
exports:
  - JobsPage
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="large">
    <page-header
      title="Worker Jobs"
      subtitle="Kick off background jobs and inspect queue health."
    />
    <n-grid :cols="2" x-gap="16" y-gap="16">
      <n-gi>
        <n-card title="Dispatch job" size="small">
          <n-form label-placement="top">
            <n-form-item label="Queue">
              <n-select v-model:value="job.queue" :options="queueOptions" />
            </n-form-item>
            <n-form-item label="Payload (JSON)">
              <n-input
                v-model:value="job.payload"
                type="textarea"
                :autosize="{ minRows: 4 }"
              />
            </n-form-item>
            <n-button type="primary" :loading="isDispatching" @click="dispatchJob">
              Enqueue job
            </n-button>
          </n-form>
        </n-card>
      </n-gi>
      <n-gi>
        <n-card title="Queue health" size="small">
          <n-space vertical>
            <n-text depth="3">Outbox queue: Healthy</n-text>
            <n-text depth="3">Billing jobs: 2 pending</n-text>
            <n-text depth="3">Provisioning: 1 retrying</n-text>
          </n-space>
        </n-card>
      </n-gi>
    </n-grid>
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.pages.jobs
purpose: Provide job dispatch form state for the admin UI.
exports:
  - state: job
patterns:
  - vue_script_setup
*/
import { reactive, ref } from "vue";
import { useMessage } from "naive-ui";
import { adminApi } from "../api/adminApi";
import type { JobRequest } from "../api/types";
import PageHeader from "../components/PageHeader.vue";

const message = useMessage();
const isDispatching = ref(false);

const queueOptions = [
  { label: "outbox-dispatch", value: "outbox-dispatch" },
  { label: "tenant-provisioning", value: "tenant-provisioning" },
  { label: "billing-reconcile", value: "billing-reconcile" }
];

const job = reactive<JobRequest>({
  queue: queueOptions[0].value,
  payload: "{\n  \"tenantId\": \"tenant-001\"\n}"
});

const dispatchJob = async () => {
  if (!job.queue) {
    message.warning("Select a queue before dispatching.");
    return;
  }

  try {
    isDispatching.value = true;
    await adminApi.enqueueJob(job);
    message.success("Job dispatched.");
  } catch (error) {
    message.warning(
      error instanceof Error ? error.message : "Failed to dispatch job."
    );
  } finally {
    isDispatching.value = false;
  }
};
</script>
