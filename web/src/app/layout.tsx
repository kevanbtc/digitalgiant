import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { APP_NAME, APP_DESCRIPTION } from "@/lib/constants";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: {
    default: APP_NAME,
    template: `%s | ${APP_NAME}`,
  },
  description: APP_DESCRIPTION,
  keywords: [
    "blockchain",
    "cryptocurrency",
    "networking",
    "referrals",
    "digital economy",
    "Web3",
    "decentralized",
  ],
  authors: [{ name: "Digital Giant Team" }],
  creator: "Digital Giant",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://digitalgiant.com",
    title: APP_NAME,
    description: APP_DESCRIPTION,
    siteName: APP_NAME,
  },
  twitter: {
    card: "summary_large_image",
    title: APP_NAME,
    description: APP_DESCRIPTION,
    creator: "@digitalgiant_",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans antialiased">
        {children}
      </body>
    </html>
  );
}
