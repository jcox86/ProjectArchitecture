<!--
module: src.adminUi.components.statCard
purpose: Present a quick statistic with a label and value.
exports:
  - StatCard
patterns:
  - naive_ui
-->
<template>
  <n-card size="small">
    <n-space vertical size="xs">
      <n-text depth="3">{{ label }}</n-text>
      <n-text class="stat-value">{{ value }}</n-text>
    </n-space>
  </n-card>
</template>

<script setup lang="ts">
/*
module: src.adminUi.components.statCard
purpose: Define props for the stat card.
exports:
  - props: label, value
patterns:
  - vue_script_setup
*/
defineProps<{
  label: string;
  value: string | number;
}>();
</script>

<style scoped>
.stat-value {
  font-size: 20px;
  font-weight: 600;
}
</style>
