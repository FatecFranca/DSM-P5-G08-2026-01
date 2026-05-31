import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Vitalis - Analise de habitos com IA",
  description: "Sistema inteligente de analise de perfil de saude e recomendacao de habitos.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
