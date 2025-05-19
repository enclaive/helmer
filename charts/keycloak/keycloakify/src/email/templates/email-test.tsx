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

import {Layout} from "../components";
import {styles} from "../constants";

interface TemplateProps extends Omit<GetTemplateProps, "plainText"> {}

const {exp} = createVariablesHelper("email-test.ftl");
const realmName = exp("realmName");

// Needed for preview email
export const previewProps = {
  locale: "en",
  themeName: "enclaive",
} as const satisfies TemplateProps;

export const templateName = "Test email";

export const Template = ({
                           locale = previewProps.locale,
                         }: TemplateProps) => {
  return (
    <Layout
      title={templateName}
      preview={`${templateName} for ${realmName}`}
      locale={locale}
    >
      <Text>
        {JSON.stringify({
          realmName,
          url: exp('url'),
          user: exp("user")
        })}
      </Text>
      <Text style={styles.text.md}>
        this is a test email
      </Text>
    </Layout>
  )
};

export const getTemplate: GetTemplate = async (props) => {
  return render(<Template {...props} />, {plainText: Boolean(props && props.plainText)});
}

export const getSubject: GetSubject = (props) => Promise.resolve(templateName);
