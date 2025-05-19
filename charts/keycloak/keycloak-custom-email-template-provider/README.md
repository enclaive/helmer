# Keycloak custom email template provider

This plugin adds `realmAttributes` to email templates that will be available by `keycloakify/keycloak-emails` like:

```javascript
const customEmailLogoURL = exp("realmAttributes.customEmailLogoURL");
const frontendURL = exp("realmAttributes.frontendURL");
const backendURL = exp("realmAttributes.backendURL");
```

## Build

```shell
mvn clean install
```

Copy `./target/custom-emcp-freemarker-email-template-provider.jar` to `../k8s/keycloak/providers`

To check that the plugin is activated open: 
1. `https://auth.dev.enclaive.cloud/admin/master/console/#/master/providers` tab 
2. Find `emailTemplate` section. It should be `custom-freemarker`