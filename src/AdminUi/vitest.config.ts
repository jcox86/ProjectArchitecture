/*
module: src.adminUi.vitestConfig
purpose: Configure Vitest for the Vue admin UI.
exports:
  - config: defineConfig
patterns:
  - vitest
  - vue
*/
import { defineConfig } from "vitest/config";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: "jsdom",
    globals: true,
    include: ["src/__tests__/**/*.spec.ts"]
  }
});
