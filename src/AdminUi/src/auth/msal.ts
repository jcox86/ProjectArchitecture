/*
module: src.adminUi.auth.msal
purpose: Configure MSAL for Entra ID sign-in and token acquisition.
exports:
  - msalInstance
  - loginRequest
  - initializeAuth
  - getActiveAccount
patterns:
  - entra_msal
*/
import {
  EventType,
  PublicClientApplication,
  type AccountInfo,
  type AuthenticationResult
} from "@azure/msal-browser";
import { appConfig } from "../appConfig";

const msalInstance = new PublicClientApplication({
  auth: {
    clientId: appConfig.entraClientId,
    authority: `https://login.microsoftonline.com/${appConfig.entraTenantId}`,
    redirectUri: appConfig.entraRedirectUri
  },
  cache: {
    cacheLocation: "localStorage"
  }
});

const loginRequest = {
  scopes: appConfig.adminApiScopes
};

const setActiveAccount = (account: AccountInfo | null) => {
  if (account) {
    msalInstance.setActiveAccount(account);
  }
};

const getActiveAccount = () => msalInstance.getActiveAccount();

const initializeAuth = async () => {
  await msalInstance.initialize();
  const redirectResult = await msalInstance.handleRedirectPromise();

  if (redirectResult?.account) {
    setActiveAccount(redirectResult.account);
    return;
  }

  const accounts = msalInstance.getAllAccounts();
  if (accounts.length > 0) {
    setActiveAccount(accounts[0]);
  }
};

msalInstance.addEventCallback((event) => {
  if (event.eventType === EventType.LOGIN_SUCCESS && event.payload) {
    const authResult = event.payload as AuthenticationResult;
    setActiveAccount(authResult.account);
  }
});

export { getActiveAccount, initializeAuth, loginRequest, msalInstance };
