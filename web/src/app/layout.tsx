import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Vitalis — Hábitos saudáveis com IA",
  description:
    "App de bem-estar que classifica seu perfil com Machine Learning e sugere cardápio, lembretes e hábitos personalizados.",
  openGraph: {
    title: "Vitalis — Hábitos saudáveis com IA",
    description:
      "Questionário, classificação ML, cardápio personalizado e gamificação.",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body className={inter.className}>{children}</body>
    </html>
  );
}