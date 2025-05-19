import {Suspense, useEffect} from "react";
import type {ClassKey} from "keycloakify/account";
import type {KcContext} from "./KcContext.ts";
import {useI18n} from "./i18n.ts";
import DefaultPage from "keycloakify/account/DefaultPage";
import Template from "./Template.tsx";
import Account from "./pages/Account.tsx";
import Sessions from "./pages/Sessions.tsx";
import '../main.css';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default function KcPage(props: { kcContext: KcContext & { realm: any } }) {
  const {kcContext} = props;
  const {i18n} = useI18n({kcContext});
  const realmName = kcContext.realm.name;
  const urlConfig = {
    backendUrl: kcContext.realm.attributes?.customBackendURL,
    frontendUrl: kcContext.realm.attributes?.customFrontendURL,
  };

  useEffect(() => {
    if (urlConfig.backendUrl) {
      const styles = document.createElement("style");
      styles.id = 'style-be'

      fetch(`${urlConfig.backendUrl}/api/public/themes/styles/${realmName}`)
        .then(response => response.ok ? response.text() : Promise.reject(response.statusText))
        .then((data) => {
          document.head.appendChild(styles);
          styles.innerHTML = data;
          const root = document.documentElement;
          window.getComputedStyle(document.querySelector(':root')!)
          root.style.setProperty("--pf-global--primary-color--100", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
          root.style.setProperty("--pf-global--primary-color--200", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 10%))');
          root.style.setProperty("--pf-global--primary-color--300", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 20%))');
          root.style.setProperty("--pf-c-form-control--focus--BorderBottomColor", 'hsl(var(--hue-primary), var(--saturation-primary), calc(var(--lightness-primary) + 10%))');
          root.style.setProperty("--masked-background", "hsl(calc(210 + 20),calc(90% - 40%),calc(calc(50% + calc(10.875%*4)) + 2.5%))");
          root.style.setProperty("--pf-c-button--m-control--after--BorderBottomColor", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
          root.style.setProperty("--color-primary", 'hsl(var(--hue-primary), var(--saturation-primary), var(--lightness-primary))');
        })
    }
  }, [urlConfig.backendUrl]);

  return (
      <Suspense>
        {(() => {
          switch (kcContext.pageId) {
            case ('account.ftl'):
              return <Account kcContext={kcContext} i18n={i18n} classes={classes} Template={Template}
                              doUseDefaultCss={true}/>
            case ('sessions.ftl'):
              return <Sessions kcContext={kcContext} i18n={i18n} classes={classes} Template={Template}
                               doUseDefaultCss={true}/>
            default:
              return <DefaultPage kcContext={kcContext} i18n={i18n} classes={classes} Template={Template}
                                  doUseDefaultCss={true}/>;
          }
        })()}
      </Suspense>
  );
}

const classes = {} satisfies { [key in ClassKey]?: string };
