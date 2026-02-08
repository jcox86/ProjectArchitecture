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

<script setup lang="ts" generic="T">
/*
module: src.adminUi.components.dataTableCard
purpose: Provide typed props for the DataTableCard component.
exports:
  - props: title, columns, data
patterns:
  - vue_script_setup
*/
import type { DataTableColumns } from "naive-ui";

defineProps<{
  title: string;
  columns: DataTableColumns<T>;
  data: T[];
  pagination?: false | { pageSize: number };
  loading?: boolean;
}>();
</script>
