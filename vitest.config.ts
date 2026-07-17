import { defineConfig } from "vitest/config"
import path from "node:path"

export default defineConfig({
  esbuild: { jsx: "automatic" },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
      "server-only": path.resolve(__dirname, "src/test/__mocks__/server-only.ts"),
    },
  },
  test: { environment: "jsdom", setupFiles: ["./src/test/setup.ts"] },
})
