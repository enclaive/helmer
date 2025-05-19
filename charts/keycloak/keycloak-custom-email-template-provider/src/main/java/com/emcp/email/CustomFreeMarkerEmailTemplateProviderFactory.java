package com.emcp.email;

import org.keycloak.Config;
import org.keycloak.email.EmailTemplateProvider;
import org.keycloak.email.EmailTemplateProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

public class CustomFreeMarkerEmailTemplateProviderFactory implements EmailTemplateProviderFactory {

    @Override
    public EmailTemplateProvider create(KeycloakSession session) {
        return new CustomFreeMarkerEmailTemplateProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }

    @Override
    public String getId() {
        return "custom-freemarker";
    }
}

 