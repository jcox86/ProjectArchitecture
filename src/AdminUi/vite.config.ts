/*
module: src.adminUi.viteConfig
purpose: Configure Vite for the admin UI build and dev server.
exports:
  - config: defineConfig
patterns:
  - vite
  - vue
*/
import fs from "node:fs";
import { resolve } from "node:path";
import { defineConfig, loadEnv } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const isProd = mode === "production";
  const adminApiBaseUrl = (env.VITE_ADMIN_API_BASE_URL ?? "/api/admin").replace(/\/$/, "");
  const proxyTarget = env.VITE_ADMIN_API_PROXY_TARGET;
  const proxySecure = env.VITE_ADMIN_API_PROXY_SECURE !== "false";
  const httpsEnabled = env.VITE_DEV_HTTPS === "true";
  const httpsCertPath = env.VITE_DEV_HTTPS_CERT;
  const httpsKeyPath = env.VITE_DEV_HTTPS_KEY;
  const httpsConfig =
    httpsEnabled && httpsCertPath && httpsKeyPath
      ? {
          cert: fs.readFileSync(resolve(httpsCertPath)),
          key: fs.readFileSync(resolve(httpsKeyPath))
        }
      : httpsEnabled
        ? {}
        : undefined;

  return {
    plugins: [vue()],
    server: {
      port: Number(env.VITE_DEV_PORT ?? 5173),
      strictPort: true,
      open: false,
      https: httpsConfig,
      proxy: proxyTarget
        ? {
            [adminApiBaseUrl]: {
              target: proxyTarget,
              changeOrigin: true,
              secure: proxySecure
            }
          }
        : undefined
    },
    build: {
      target: "es2020",
      sourcemap: !isProd,
      cssCodeSplit: true,
      minify: isProd ? "esbuild" : false,
      reportCompressedSize: true,
      chunkSizeWarningLimit: 650,
      rollupOptions: {
        output: {
          manualChunks: (id) => {
            if (!id.includes("node_modules")) {
              return undefined;
            }

            if (id.includes("@azure/msal-browser")) {
              return "msal";
            }

            if (id.includes("naive-ui") || id.includes("vue-router") || id.includes("vue")) {
              return "ui";
            }

            return undefined;
          }
        }
      }
    }
  };
});
