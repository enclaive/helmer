/* eslint-disable @typescript-eslint/no-empty-object-type */
import type { ExtendKcContext } from "keycloakify/login";
import type { KcEnvName, ThemeName } from "../kc.gen.tsx";

export type KcContextExtension = {
    themeName: ThemeName;
    properties: Record<KcEnvName, string> & {};
    realm: {
      attributes: {
        customBackendURL?: string;
        customEmailLogoURL?: string;
        customFrontendURL?: string;
        customIconURL?: string;
        customLogoURL?: string;
      }
    }
    ftlTemplateFileName: string;
    url: Record<string, string>;
    // NOTE: Here you can declare more properties to extend the KcContext
    // See: https://docs.keycloakify.dev/faq-and-help/some-values-you-need-are-missing-from-in-kccontext
};

export type KcContextExtensionPerPage = {};

export type KcContext = ExtendKcContext<KcContextExtension, KcContextExtensionPerPage>;
