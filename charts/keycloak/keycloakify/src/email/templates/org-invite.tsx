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

const { exp } = createVariablesHelper("org-invite.ftl");
const organizationName = exp("organization.name");
const realmName = exp("realmName");

// Needed for preview email
export const previewProps: TemplateProps = {
  locale: "en",
  themeName: "vanilla",
};

export const templateName = "You're Invited to Join a Team";

export const Template = ({ locale }: TemplateProps) => {
  return (
    <Layout
      title={templateName}
      preview={`You've been invited to join ${organizationName}`}
      locale={locale}
    >
      <Text style={styles.text.md}>
        You have been invited to join the team <strong>{organizationName}</strong>. Click the link below to accept the
        invitation and complete your registration.
      </Text>
      <ExpButtonLink
        href={exp("link")}
        realmName={realmName}
        linkExpiration={exp("linkExpirationFormatter(linkExpiration)")}
      >
        Join {organizationName}
      </ExpButtonLink>
      <Text style={styles.text.xs}>
        This invitation will expire within {exp("linkExpirationFormatter(linkExpiration)")} hours.
      </Text>
      <Text style={styles.text.xs}>
        If you didn't expect this invitation, you can safely ignore this email.
      </Text>
    </Layout>
  );
}

export const getTemplate: GetTemplate = (props) => {
  return render(<Template {...props} />, { plainText: props.plainText });
};

export const getSubject: GetSubject = (props) => Promise.resolve(templateName);
