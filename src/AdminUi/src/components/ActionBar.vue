<!--
module: src.adminUi.components.actionBar
purpose: Provide a common row of primary and secondary actions.
exports:
  - ActionBar
patterns:
  - naive_ui
-->
<template>
  <n-space align="center" justify="space-between">
    <slot name="left">
      <n-text depth="3">{{ hint }}</n-text>
    </slot>
    <n-space>
      <n-button v-if="secondaryLabel" secondary @click="emit('secondary')">
        {{ secondaryLabel }}
      </n-button>
      <n-button type="primary" @click="emit('primary')">
        {{ primaryLabel }}
      </n-button>
    </n-space>
  </n-space>
</template>

<script setup lang="ts">
/*
module: src.adminUi.components.actionBar
purpose: Define props for ActionBar buttons.
exports:
  - props: primaryLabel, secondaryLabel, hint
patterns:
  - vue_script_setup
*/
defineProps<{
  primaryLabel: string;
  secondaryLabel?: string;
  hint?: string;
}>();
const emit = defineEmits<{
  (event: "primary"): void;
  (event: "secondary"): void;
}>();
</script>
