<!--
module: src.adminUi.app
purpose: Render the admin UI shell with Entra sign-in gating.
exports:
  - App
patterns:
  - naive_ui
  - entra_msal
-->
<template>
  <n-config-provider>
    <n-message-provider>
      <n-dialog-provider>
        <n-notification-provider>
          <div class="app-shell">
            <n-spin v-if="!auth.isReady.value" size="large">
              <n-text>Loading admin console...</n-text>
            </n-spin>
            <n-card v-else-if="!isEntraConfigured" class="auth-card">
              <n-space vertical>
                <n-text class="headline">Admin Console Setup</n-text>
                <n-alert type="warning" title="Missing Entra configuration">
                  Provide Entra client ID and tenant ID before signing in.
                </n-alert>
                <n-text depth="3">
                  Set `VITE_ENTRA_CLIENT_ID`, `VITE_ENTRA_TENANT_ID`, and
                  `VITE_ADMIN_API_SCOPE` in `.env.local`.
                </n-text>
              </n-space>
            </n-card>
            <n-card v-else-if="!auth.isAuthenticated.value" class="auth-card">
              <n-space vertical>
                <n-text class="headline">Admin Console</n-text>
                <n-text depth="3">
                  Sign in with your Entra ID admin account to manage tenants,
                  billing, flags, and system jobs.
                </n-text>
                <n-button type="primary" @click="signIn">
                  Sign in with Entra ID
                </n-button>
              </n-space>
            </n-card>
            <admin-layout v-else />
          </div>
        </n-notification-provider>
      </n-dialog-provider>
    </n-message-provider>
  </n-config-provider>
</template>

<script setup lang="ts">
/*
module: src.adminUi.app
purpose: Wire auth state into the root view.
exports:
  - state: auth
patterns:
  - vue_script_setup
*/
import {
  NAlert,
  NButton,
  NCard,
  NConfigProvider,
  NDialogProvider,
  NMessageProvider,
  NNotificationProvider,
  NSpin,
  NText
} from "naive-ui";
import { isEntraConfigured } from "./appConfig";
import { useAuth } from "./auth/useAuth";
import AdminLayout from "./layouts/AdminLayout.vue";

const auth = useAuth();

const signIn = async () => {
  await auth.login();
};
</script>

<style scoped>
.app-shell {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.auth-card {
  width: 420px;
}

.headline {
  font-size: 22px;
  font-weight: 600;
}
</style>
