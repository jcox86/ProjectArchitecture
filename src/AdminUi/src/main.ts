/*
module: src.adminUi.main
purpose: Bootstrap the Vue admin UI with auth initialization and routing.
exports:
  - bootstrap: createApp
patterns:
  - vue_bootstrap
  - entra_msal
*/
import { createApp } from "vue";
import App from "./App.vue";
import { naive } from "./naive";
import { router } from "./router";
import { useAuth } from "./auth/useAuth";
import "./styles.css";

const app = createApp(App);
app.use(router);
app.use(naive);

const auth = useAuth();
auth
  .init()
  .catch(() => {
    // Auth init failures are handled in the UI.
  })
  .finally(() => {
    app.mount("#app");
  });
