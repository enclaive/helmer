import type {DeepPartial} from "keycloakify/tools/DeepPartial";
import type {KcContext} from "./KcContext.ts";
import KcPage from "./KcPage.tsx";
import {createGetKcContextMock} from "keycloakify/login/KcContext";
import type {KcContextExtension, KcContextExtensionPerPage} from "./KcContext.ts";
import {themeNames, kcEnvDefaults} from "../kc.gen.tsx";

const kcContextExtension: KcContextExtension = {
  themeName: themeNames[0],
  properties: {
    ...kcEnvDefaults
  },
  ftlTemplateFileName: "login-username.ftl",
  url: {
    loginUrl: "/login",
    registrationUrl: "/registration"
  },
  realm: {
    attributes: {
      customBackendURL: "",
      customEmailLogoURL: "https://placehold.co/64x64",
      customFrontendURL: "",
      customIconURL: "https://placehold.co/64x64",
      customLogoURL: "https://placehold.co/128x64"
    }
  },
};

const kcContextExtensionPerPage: KcContextExtensionPerPage = {};

export const {getKcContextMock} = createGetKcContextMock({
  kcContextExtension,
  kcContextExtensionPerPage,
  overrides: {},
  overridesPerPage: {}
});

export function createKcPageStory<PageId extends KcContext["pageId"]>(params: {
  pageId: PageId;
}) {
  const {pageId} = params;

  function KcPageStory(props: {
    kcContext?: DeepPartial<Extract<KcContext, { pageId: PageId }>>;
  }) {
    const {kcContext: overrides} = props;

    const kcContextMock = getKcContextMock({
      pageId,
      overrides
    });

    return <KcPage kcContext={kcContextMock}/>;
  }

  return {KcPageStory};
}
