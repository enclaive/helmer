import React from "react";

import {
  GetSubject,
  GetTemplate,
  GetTemplateProps,
  createVariablesHelper,
} from "keycloakify-emails";

import {render, Text} from "jsx-email";
import {ExpButtonLink, Layout} from "../components";
import {styles} from "../constants";

interface TemplateProps extends Omit<GetTemplateProps, "plainText"> {
}

const {exp} = createVariablesHelper("password-reset.ftl");
const realmName = exp("realmName");

export const templateName = "Reset Your Password";

export const Template = ({locale}: TemplateProps) => {
  return (
    <Layout
      title={templateName}
      locale={locale}
    >
      <Text style={styles.text.md}>
        A request to reset your {realmName} account password has been received. If you initiated this request, click
        the button below to reset your password:
      </Text>
      <ExpButtonLink
        realmName={realmName}
        href={exp("link")}
        linkExpiration={exp("linkExpirationFormatter(linkExpiration)")}
      >
        {templateName}
      </ExpButtonLink>
      <Text style={styles.text.xs}>
        If you did not request a password reset, please disregard this message. Your account remains secure.
      </Text>
    </Layout>
  );
}

export const getTemplate: GetTemplate = (props) => render(<Template {...props} />, {plainText: props.plainText});
export const getSubject: GetSubject = (props) => Promise.resolve(templateName);
