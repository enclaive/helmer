package com.emcp.email;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.keycloak.email.EmailException;
import org.keycloak.email.EmailTemplateProvider;
import org.keycloak.email.freemarker.FreeMarkerEmailTemplateProvider;
import org.keycloak.models.KeycloakSession;

public class CustomFreeMarkerEmailTemplateProvider extends FreeMarkerEmailTemplateProvider {
    public CustomFreeMarkerEmailTemplateProvider(KeycloakSession session) {
        super(session);
    }

    protected void addCustomRealmAttributes(Map<String, Object> attributes) {
        if (realm != null && realm.getAttributes() != null) {
            Map<String, String> realmAttributes = realm.getAttributes();
            Map<String, Object> customAttributes = new HashMap<>();

            for (Map.Entry<String, String> entry : realmAttributes.entrySet()) {
                if (entry.getKey().startsWith("custom")) {
                    customAttributes.put(entry.getKey(), entry.getValue());
                }
            }

            if (!customAttributes.isEmpty()) {
                attributes.put("realmAttributes", customAttributes);
            }
        }
    }

    @Override
    protected EmailTemplate processTemplate(String subjectKey, List<Object> subjectAttributes, String template, Map<String, Object> attributes) throws EmailException {
        addCustomRealmAttributes(attributes);

        return super.processTemplate(subjectKey, subjectAttributes, template, attributes);
    }
}