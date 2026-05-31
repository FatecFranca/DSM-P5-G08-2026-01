"use client";

import { useEffect, useState } from "react";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3333";

type Stats = {
  apiStatus: string;
  clusters: number;
  error?: string;
};

export default function AdminPage() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    async function load() {
      try {
        const [health, clustersRes] = await Promise.all([
          fetch(`${API_URL}/health`),
          fetch(`${API_URL}/health/clusters`),
        ]);
        const healthData = await health.json();
        const clustersData = await clustersRes.json();
        setStats({
          apiStatus: healthData.status ?? "unknown",
          clusters: clustersData.clusters?.length ?? 0,
        });
      } catch {
        setStats({ apiStatus: "offline", clusters: 0, error: "API indisponivel" });
      }
    }
    load();
  }, []);

  return (
    <main className="container" style={{ padding: "4rem 1.5rem" }}>
      <h1 style={{ fontSize: "1.8rem", marginBottom: "0.5rem" }}>Painel Admin</h1>
      <p style={{ color: "#9aa8bc", marginBottom: "2rem" }}>
        Visao basica do sistema. Painel completo sera expandido na proxima etapa.
      </p>

      <div className="features" style={{ padding: 0 }}>
        <article className="card">
          <h3>Status da API</h3>
          <p>{stats ? stats.apiStatus : "Carregando..."}</p>
        </article>
        <article className="card">
          <h3>Clusters definidos</h3>
          <p>{stats ? stats.clusters : "-"}</p>
        </article>
        <article className="card">
          <h3>Endpoint</h3>
          <p style={{ wordBreak: "break-all" }}>{API_URL}</p>
        </article>
      </div>

      {stats?.error && (
        <p style={{ color: "#f87171", marginTop: "1.5rem" }}>{stats.error}</p>
      )}

      <p style={{ marginTop: "2rem" }}>
        <a href="/">Voltar para landing</a>
      </p>
    </main>
  );
}
