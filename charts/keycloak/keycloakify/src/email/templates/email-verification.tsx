import React from "react";

import {
  GetSubject,
  GetTemplate,
  GetTemplateProps,
  createVariablesHelper,
} from "keycloakify-emails";

import {
  Text,
  render,
} from "jsx-email";

import { ExpButtonLink, Layout } from "../components";
import { styles } from "../constants";

interface TemplateProps extends Omit<GetTemplateProps, "plainText"> {}

const { exp }   = createVariablesHelper("email-verification.ftl");
const realmName = exp("realmName");

// Needed for preview email
export const previewProps: TemplateProps = {
  locale    : "en",
  themeName : "enclaive",
};

export const templateName = "Confirm your Email Address";

export const Template = ({ locale }: TemplateProps) => {
  return (
    <Layout
      title={templateName}
      preview={`Verification link from ${realmName}`}
      locale={locale}
    >
      <Text style={styles.text.md}>
        Someone has created a {realmName} account with this email
        address. If this was you, click the link below to verify your email
        address
      </Text>
      <ExpButtonLink
        href={exp("link")}
        realmName={realmName}
        linkExpiration={exp("linkExpirationFormatter(linkExpiration)")}
      >
        {templateName}
      </ExpButtonLink>
      <Text style={styles.text.xs}>
        If you didn't create this account, just ignore this message.
      </Text>
    </Layout>
  );
}

export const getTemplate: GetTemplate = (props) => {
  return render(<Template {...props} />, { plainText: props.plainText });
};

export const getSubject: GetSubject = (props) => Promise.resolve(templateName);
