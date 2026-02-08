<!--
module: src.adminUi.components.dataTableCard
purpose: Render a Naive UI data table inside a card with a title.
exports:
  - DataTableCard
patterns:
  - naive_ui
-->
<template>
  <n-card :title="title" size="small">
    <n-data-table
      :columns="columns"
      :data="data"
      :pagination="pagination"
      :loading="loading"
    />
  </n-card>
</template>

<script setup lang="ts">
/*
module: src.adminUi.components.dataTableCard
purpose: Provide typed props for the DataTableCard component.
exports:
  - props: title, columns, data
patterns:
  - vue_script_setup
*/
import type { PropType } from "vue";
import type { DataTableColumns } from "naive-ui";

defineProps({
  title: { type: String, required: true },
  columns: {
    type: Array as PropType<DataTableColumns<unknown>>,
    required: true
  },
  data: {
    type: Array as PropType<unknown[]>,
    required: true
  },
  pagination: {
    type: [Object, Boolean] as PropType<false | { pageSize: number }>,
    default: undefined
  },
  loading: {
    type: Boolean,
    default: false
  }
});
</script>
