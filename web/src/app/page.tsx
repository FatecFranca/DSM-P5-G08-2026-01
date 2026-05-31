export default function HomePage() {
  return (
    <main>
      <section className="hero container">
        <span className="badge">PI - Aprendizagem de Maquina · FATEC Franca</span>
        <h1>Analise inteligente de habitos e bem-estar</h1>
        <p>
          Responda perguntas sobre sua rotina, alimentacao e sono. A IA classifica seu perfil
          e sugere habitos personalizados — sem diagnostico medico.
        </p>
        <div className="actions">
          <a className="btn btn-primary" href="#features">
            Como funciona
          </a>
          <a className="btn btn-secondary" href="/admin">
            Painel admin
          </a>
        </div>
      </section>

      <section id="features" className="features container">
        <article className="card">
          <h3>Classificacao ML</h3>
          <p>
            Logistic Regression classifica seu perfil em Saudavel Ativo, Moderado, Sedentario ou Em Risco.
          </p>
        </article>
        <article className="card">
          <h3>Clusterizacao</h3>
          <p>K-Means agrupa usuarios com habitos semelhantes para comparacao e insights.</p>
        </article>
        <article className="card">
          <h3>Recomendacoes</h3>
          <p>Sugestoes de rotina, alimentacao, hidratacao e exercicio baseadas no seu perfil.</p>
        </article>
        <article className="card">
          <h3>Gamificacao</h3>
          <p>Pontos, niveis e streaks por completar lembretes de agua, refeicao e sono.</p>
        </article>
      </section>

      <section className="container disclaimer">
        Este sistema nao realiza diagnostico medico. Apenas classifica perfil comportamental
        e sugere habitos saudaveis com base em machine learning.
      </section>

      <footer className="container">
        Vitalis · DSM P5 G08 · 2026
      </footer>
    </main>
  );
}
