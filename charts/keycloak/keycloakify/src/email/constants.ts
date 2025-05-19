import type { CSSProperties } from "react";

const DEFAULT_BE_URL = "http://localhost:8080" as const;

export const BE_URL = process.env.REACT_APP_BE_URL || DEFAULT_BE_URL;
const REALM_PATH    = "api/public/realms" as const;

export const REALM_URL = `${BE_URL}/${REALM_PATH}` as const;

const THEME_PATH      = "themes" as const;

type addPath<Url extends string, Path extends string> = `${Url}/${Path}`;
export const addPath = <Url extends string>(url: Url) => <Path extends string>(path: Path): addPath<Url, Path> => `${url}/${path}`;

export type themeUrl<Realm extends string> = `${typeof REALM_URL}/${Realm}/${typeof THEME_PATH}`;

export const themeUrl = (realmName: string) => `${REALM_URL}/${realmName}/${THEME_PATH}` as const;

const COLORS = [
  "primary",
  "success",
  "secondary",
  "danger",
  "gray"
] as const satisfies readonly string[];

type x16c = "a" | "b" | "c" | "d" | "e" | "f";
type x10  = `${0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9}`;
type e3   = `${x10 | x16c}${x10 | x16c}${x10 | x16c}`;

export const colors = {
  white   : "#ffffff",
  black   : "#000000",
  gray    : "#777777",
  primary : "#F2800D",
} as const satisfies Record<string, `#${string}${e3 | Uppercase<e3>}`>;

const imageUrlTail = "/pixel.png" as const;

const dynamicPixelColor = <Realm extends string>(realmName: Realm) => Object.fromEntries(COLORS.map((color) => [
  color,
  `${themeUrl(realmName)}/styles/${color}${imageUrlTail}`,
])) as { readonly [key in typeof COLORS[number]]: `${themeUrl<Realm>}/styles/${key}${typeof imageUrlTail}` };

const main = {
  backgroundColor : "#f6f9fc",
  fontFamily      : 'Proxima Nova, Arial, Helvetica, sans-serif',
  fontSize        : "16px",
  fontWeight      : "400",
} as const satisfies CSSProperties;

const container = {
  backgroundColor : colors.white,
  margin          : "16px auto 64px",
  padding         : "24px 0 38px",
  maxWidth        : "100%",
} as const satisfies CSSProperties;

const box = {
  padding: "16px 48px",
} as const satisfies CSSProperties;

const textMd = {
  color      : colors.gray,
  fontFamily : main.fontFamily,
  fontWeight : main.fontWeight,
  fontSize   : main.fontSize,
  lineHeight : "24px",
  textAlign  : "left",
} as const satisfies CSSProperties;

const textXl = {
  ...textMd,
  fontSize   : "32px",
  lineHeight : "40px",
} as const satisfies CSSProperties;

const textLg = {
  ...textMd,
  fontSize   : "24px",
  lineHeight : "32px",
} as const satisfies CSSProperties;

const textSm = {
  ...textMd,
  fontSize   : "14px",
  lineHeight : "20px",
} as const satisfies CSSProperties;

const textXs = {
  ...textMd,
  fontSize   : "12px",
  lineHeight : "14px",
} as const satisfies CSSProperties;

const text = {
  xl: textXl,
  lg: textLg,
  md: textMd,
  sm: textSm,
  xs: textXs,
} as const satisfies Record<string, CSSProperties>;


const logo = (src: string) => ({
  maxWidth           : "250px",
  minWidth           : "100px",
  maxHeight          : "100px",
  minHeight          : "50px",
  width              : "auto",
  height             : "auto",
  backgroundImage    : `url(${src})`,
  backgroundSize     : "contain",
  backgroundPosition : "center center",
  backgroundRepeat   : "no-repeat",
}) as const satisfies CSSProperties;

const button = <Realm extends string>(realmName: Realm) => ({
  display          : "inline-block",
  textAlign        : "center",
  verticalAlign    : "middle",
  width            : "100%",
  maxWidth         : "100%",
  minWidth         : "16px",
  fontFamily       : main.fontFamily,
  fontSize         : text.md.fontSize,
  minHeight        : text.md.fontSize,
  fontWeight       : '600',
  paddingTop       : "8px",
  paddingBottom    : "8px",
  paddingLeft      : "16px",
  paddingRight     : "16px",
  textDecoration   : 'none',
  backgroundImage  : `url(${dynamicPixelColor(realmName).primary})`,
  backgroundRepeat : "repeat",
  backgroundSize   : "100% 100%",
  backgroundColor  : colors.primary,
  color            : colors.white,
  borderRadius     : "4px",
  cursor           : "pointer",
  userSelect       : "none",
} as const satisfies CSSProperties);

export const styles = {
  colors,
  dynamicPixelColor,
  main,
  button,
  container,
  text,
  box,
  logo,
} as const;
