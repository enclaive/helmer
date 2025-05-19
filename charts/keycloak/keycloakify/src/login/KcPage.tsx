import { Suspense, lazy, useEffect } from "react";
import type { ClassKey } from "keycloakify/login";
import type { KcContext } from "./KcContext.ts";
import { useI18n } from "./i18n.ts";
import DefaultPage from "keycloakify/login/DefaultPage";
import Template from "./Template.tsx";
const UserProfileFormFields = lazy(
  () => import("keycloakify/login/UserProfileFormFields")
);
import '../main.css';
import LogoWithName from "../icons/LogoWithName.tsx";
import LoginUsername from "./pages/LoginUsername.tsx";

const doMakeUserConfirmPassword = true;

const Header = ({ kcContext }: {kcContext: KcContext }) => {
  const customLogoURL = kcContext.realm.attributes?.customLogoURL;
  const realName = kcContext.realm.name;
  const registrationDisabled = "registrationDisabled" in kcContext && Boolean(kcContext.registrationDisabled);
  const registrationAllowed = "registrationAllowed" in kcContext.realm && Boolean(kcContext.realm.registrationAllowed);
  return (
    <header className="emc-header">
      <div className="logo-block">
        <a style={{ textDecoration: "none", color: "inherit" }} href={kcContext.realm.attributes?.customFrontendURL ?? "#"}>
          {customLogoURL ? (
            <img src={customLogoURL} style={{ objectFit: "contain", maxHeight: "64px" }} alt={realName} />
          ): <LogoWithName className="logo" />}
        </a>
      </div>
      <div className="enc-header-register">
        {
          (
            (!registrationDisabled && registrationAllowed) &&
            (kcContext.ftlTemplateFileName === 'login.ftl' || kcContext.pageId === 'login-username.ftl')
          )
            ? <><div>Don&apos;t have an account?</div><a href={kcContext.url.registrationUrl}>Sign up</a></>
            : null
        }
        {kcContext.ftlTemplateFileName === 'register.ftl' ?
          <><div>Already have an account?</div><a href={kcContext.url.loginUrl}>Sign in</a></> : null}
      </div>
    </header>
  )
}

export default function KcPage(props: { kcContext: KcContext }) {
  const { kcContext } = props;
  const { i18n } = useI18n({ kcContext });
  const realmName = kcContext.realm.name;

  const backendUrl = kcContext.realm.attributes?.customBackendURL;

  useEffect(() => {
    if (backendUrl) {
      const styles = document.createElement("style");
      styles.id = 'style-be'

      fetch(`${backendUrl}/api/public/themes/styles/${realmName}`)
        .then(response => response.ok ? response.text() : Promise.reject(response.statusText))
        .then((data) => {
          if (data) {
            document.head.appendChild(styles);
            styles.innerHTML = data;
            const root = document.documentElement;
            if (root) {
              window.getComputedStyle(document.querySelector(':root')!)
              root.style.setProperty("--pf-global--primary-color--100", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
              root.style.setProperty("--pf-global--primary-color--200", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 10%))');
              root.style.setProperty("--pf-global--primary-color--300", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 20%))');
              root.style.setProperty("--pf-c-form-control--focus--BorderBottomColor", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 10%))');
              root.style.setProperty("--masked-background", "hsl(calc(210 + 20),calc(90% - 40%),calc(calc(50% + calc(10.875%*4)) + 2.5%))");
              root.style.setProperty("--pf-c-button--m-control--after--BorderBottomColor", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
              root.style.setProperty("--color-primary", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
            }
          } else return Promise.reject('Can\'t get styles. Data is empty')
        }, console.error);
    }
  }, [backendUrl]);

  return (
    <Suspense>
      {(() => {
        switch (kcContext.pageId) {
          case ('login-username.ftl'):
            return <>
              <Header kcContext={kcContext} />
              <LoginUsername kcContext={kcContext} i18n={i18n} classes={classes} Template={Template} doUseDefaultCss={true} />
            </>
          default:
            return (
              <>
                <Header kcContext={kcContext} />
                <DefaultPage
                  kcContext={kcContext}
                  i18n={i18n}
                  classes={classes}
                  Template={Template}
                  doUseDefaultCss={true}
                  UserProfileFormFields={UserProfileFormFields}
                  doMakeUserConfirmPassword={doMakeUserConfirmPassword}
                />
              </>
            );
        }
      })()}
    </Suspense>
  );
}

const classes = {} satisfies { [key in ClassKey]?: string };
