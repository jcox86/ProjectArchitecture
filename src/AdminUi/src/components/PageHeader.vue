<!--
module: src.adminUi.components.pageHeader
purpose: Provide consistent page titles and descriptions.
exports:
  - PageHeader
patterns:
  - naive_ui
-->
<template>
  <n-space vertical size="xs">
    <n-text class="page-title">{{ title }}</n-text>
    <n-text depth="3">{{ subtitle }}</n-text>
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.components.pageHeader
purpose: Provide props for the page header component.
exports:
  - props: title, subtitle
patterns:
  - vue_script_setup
*/
defineProps<{
  title: string;
  subtitle: string;
}>();
</script>

<style scoped>
.page-title {
  font-size: 24px;
  font-weight: 600;
}
</style>
