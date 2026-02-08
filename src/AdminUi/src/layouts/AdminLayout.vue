<!--
module: src.adminUi.layouts.adminLayout
purpose: Provide the main shell layout and navigation for admin pages.
exports:
  - AdminLayout
patterns:
  - naive_ui
  - vue_router
-->
<template>
  <n-layout has-sider class="layout-root">
    <n-layout-sider bordered width="240">
      <n-space vertical class="sider-content" size="large">
        <n-text class="logo">Admin Console</n-text>
        <n-menu
          :options="menuOptions"
          :value="selectedKey"
          @update:value="onSelect"
        />
      </n-space>
    </n-layout-sider>
    <n-layout>
      <n-layout-header bordered class="header">
        <n-space align="center" justify="space-between">
          <n-space align="center">
            <n-text depth="2">Environment</n-text>
            <n-tag size="small">{{ envLabel }}</n-tag>
          </n-space>
          <n-space align="center">
            <n-text depth="3">{{ accountLabel }}</n-text>
            <n-button secondary @click="logout">Sign out</n-button>
          </n-space>
        </n-space>
      </n-layout-header>
      <n-layout-content class="content">
        <router-view />
      </n-layout-content>
    </n-layout>
  </n-layout>
</template>

<script setup lang="ts">
/*
module: src.adminUi.layouts.adminLayout
purpose: Provide navigation state for the admin layout.
exports:
  - state: menuOptions
patterns:
  - vue_composition
*/
import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { appConfig } from "../appConfig";
import { useAuth } from "../auth/useAuth";

const router = useRouter();
const route = useRoute();
const auth = useAuth();

const menuOptions = [
  { label: "Tenants", key: "/tenants" },
  { label: "Flags", key: "/flags" },
  { label: "Plans & Add-ons", key: "/plans" },
  { label: "Pricing", key: "/pricing" },
  { label: "Billing Status", key: "/billing" },
  { label: "Announcements", key: "/announcements" },
  { label: "Worker Jobs", key: "/jobs" },
  { label: "Audit Logs", key: "/audit" }
];

const selectedKey = computed(() => route.path);
const onSelect = (key: string) => {
  router.push(key);
};

const accountLabel = computed(
  () => auth.account.value?.name ?? auth.account.value?.username ?? "Admin"
);
const envLabel = computed(() => appConfig.adminApiBaseUrl);

const logout = () => auth.logout();
</script>

<style scoped>
.layout-root {
  height: 100%;
}

.sider-content {
  padding: 16px;
}

.logo {
  font-size: 18px;
  font-weight: 700;
}

.header {
  padding: 12px 24px;
}

.content {
  padding: 24px;
}
</style>
