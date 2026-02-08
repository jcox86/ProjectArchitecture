/*
module: src.adminUi.auth.useAuth
purpose: Provide a shared auth state and helpers for Entra sign-in and tokens.
exports:
  - useAuth
patterns:
  - composition_api
  - entra_msal
*/
import { computed, ref } from "vue";
import { appConfig, isEntraConfigured } from "../appConfig";
import { getActiveAccount, initializeAuth, loginRequest, msalInstance } from "./msal";

const isReady = ref(false);
const account = ref(getActiveAccount());

const syncAccount = () => {
  account.value = getActiveAccount();
};

const init = async () => {
  if (isReady.value) {
    return;
  }

  if (!isEntraConfigured) {
    isReady.value = true;
    return;
  }

  await initializeAuth();
  syncAccount();
  isReady.value = true;
};

msalInstance.addEventCallback(() => {
  syncAccount();
});

const login = async () => {
  if (!isEntraConfigured) {
    throw new Error("Missing Entra configuration.");
  }

  await msalInstance.loginRedirect(loginRequest);
};

const logout = async () => {
  await msalInstance.logoutRedirect({
    account: getActiveAccount() ?? undefined
  });
};

const getAccessToken = async () => {
  if (!appConfig.adminApiScopes.length) {
    return "";
  }

  const request = {
    scopes: appConfig.adminApiScopes,
    account: getActiveAccount() ?? undefined
  };

  try {
    const result = await msalInstance.acquireTokenSilent(request);
    return result.accessToken;
  } catch {
    await msalInstance.acquireTokenRedirect(request);
    return "";
  }
};

export const useAuth = () => ({
  account,
  isAuthenticated: computed(() => !!account.value),
  isReady,
  init,
  login,
  logout,
  getAccessToken
});
