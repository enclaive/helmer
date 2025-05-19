import React from "react";

import {
  Body,
  Container,
  Head,
  Html,
  Img,
  Link,
  Preview,
  Section,
  Text,
} from "jsx-email";

import {styles} from "./constants";
import * as Fm from "keycloakify-emails/jsx-email";

export const Logo = () => (
  <Fm.If condition="realmAttributes.customEmailLogoURL?? && realmAttributes.customEmailLogoURL != ''">
    <Fm.Then>
      <Img
        alt="Logo"
        style={styles.logo(Fm.exp("realmAttributes.customEmailLogoURL"))}
        src={Fm.exp("realmAttributes.customEmailLogoURL")}
      />
    </Fm.Then>
    <Fm.Else>
      <Img
        alt="Logo"
        style={styles.logo(Fm.exp("url.resourcesUrl") + "/logo.png")}
        src={Fm.exp("url.resourcesUrl") + "/logo.png"}
      />
    </Fm.Else>
  </Fm.If>
);

interface ButtonLinkProps {
  children: React.ReactNode;
  realmName: string;
  href: string;
}

interface ExpButtonLinkProps extends ButtonLinkProps {
  linkExpiration: string;
}

export const ButtonLink = <T extends ButtonLinkProps>({
                                                        href,
                                                        children,
                                                        realmName,
                                                      }: T) => (
  <Link
    href={href}
    style={styles.button(realmName)}
  >
    {children}
  </Link>
);

export const ExpButtonLink = <T extends ExpButtonLinkProps>({
                                                              children,
                                                              href,
                                                              realmName,
                                                              linkExpiration,
                                                            }: T) => (
  <>
    <ButtonLink
      href={href}
      realmName={realmName}
    >
      {children}
    </ButtonLink>
    <Text style={styles.text.sm}>
      This link will expire in {linkExpiration} minutes.
    </Text>
  </>
);

export const Layout = ({
                         children,
                         title,
                         preview = title,
                         locale = "en",
                       }: {
  children: React.ReactNode;
  title: string;
  preview?: string;
  locale?: string;
}) => (
  <Html lang={locale}>
    <Head/>
    <Preview>{preview}</Preview>
    <Body style={styles.main}>
      <Container style={styles.container}>
        <Logo/>
        <Section style={styles.box}>
          <Text style={styles.text.xl}>
            {title}
          </Text>
          {children}
        </Section>
      </Container>
    </Body>
  </Html>
);
