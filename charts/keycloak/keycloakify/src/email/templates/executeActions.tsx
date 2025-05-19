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

import {ExpButtonLink, Layout} from "../components";
import { styles } from "../constants";

interface TemplateProps extends Omit<GetTemplateProps, "plainText"> {}

const { exp } = createVariablesHelper("executeActions.ftl");
const realmName = exp("realmName");

// Needed for preview email
export const previewProps = {
  locale: "en",
  themeName: "enclaive",
};

export const templateName = "Set Your Password";

export const Template = ({ locale }: {
  locale: string;
}) => {
  return (
    <Layout
      title={templateName}
      preview={`You have been added to ${realmName}`}
      locale={locale}
    >
      <Text style={styles.text.md}>
        You have been added to {realmName}. To continue, please set your password and complete your profile setup.
      </Text>
      <ExpButtonLink
        href={exp("link")}
        realmName={realmName}
        linkExpiration={exp("linkExpirationFormatter(linkExpiration)")}
      >
        {templateName}
      </ExpButtonLink>
      <Text style={styles.text.xs}>
        This link will expire in {exp("linkExpirationFormatter(linkExpiration)")} minutes.
      </Text>
      <Text style={styles.text.xs}>
        If you did not expect this message, please ignore it.
      </Text>
    </Layout>
  );
}

export const getTemplate: GetTemplate = (props) => {
  return render(<Template {...props} />, { plainText: props.plainText });
};

export const getSubject: GetSubject = (props) => Promise.resolve(templateName);
