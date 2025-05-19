import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { keycloakify } from "keycloakify/vite-plugin";
import { buildEmailTheme } from "keycloakify-emails";
import path from "node:path";

export default defineConfig({
  plugins: [
    react(),
    keycloakify({
      themeName: ["enclaive"],
      accountThemeImplementation: "Multi-Page",
      extraThemeProperties: [
        "REACT_APP_BE_URL=" + process.env.REACT_APP_BE_URL,
      ],
      keycloakVersionTargets: {
        "all-other-versions": false,
        "26-and-above": true
      },
      postBuild: async (buildContext) => {
        await buildEmailTheme({
          templatesSrcDirPath: path.join(
            import.meta.dirname,
            "src",
            "email",
            "templates",
          ),
          themeNames: buildContext.themeNames,
          keycloakifyBuildDirPath: buildContext.keycloakifyBuildDirPath,
          locales: ["en", "pl"],
          cwd: import.meta.dirname,
          esbuild: {}, // optional esbuild options
        });
      },
    }),
  ],
});
