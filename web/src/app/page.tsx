import { PhoneMockup } from "../components/phone-mockup";

const features = [
  {
    title: "Questionário inteligente",
    text: "Perguntas simples sobre rotina, sono, alimentação e atividade física.",
    icon: "📋",
  },
  {
    title: "Classificação com ML",
    text: "Logistic Regression define seu perfil: ativo, moderado, sedentário ou em atenção.",
    icon: "🧠",
  },
  {
    title: "Cardápio personalizado",
    text: "Sugestões de refeições com alimentos e quantidades, adaptadas ao seu perfil.",
    icon: "🥗",
  },
  {
    title: "Lembretes e gamificação",
    text: "Água, refeições e sono no horário certo — com pontos e níveis por hábitos cumpridos.",
    icon: "🔔",
  },
];

const steps = [
  {
    n: "01",
    title: "Crie sua conta",
    text: "Cadastro rápido no app Flutter. Seus dados ficam seguros na nuvem.",
  },
  {
    n: "02",
    title: "Responda o questionário",
    text: "A IA analisa seus hábitos e classifica seu perfil de bem-estar.",
  },
  {
    n: "03",
    title: "Siga seu plano",
    text: "Receba dicas, cardápio, lembretes e acompanhe sua evolução na Home.",
  },
];

export default function HomePage() {
  return (
    <>
      <header className="site-header container">
        <a className="logo" href="/">
          <span className="logo-mark">♥️</span>
          Vitalis
        </a>
        <nav className="site-nav">
          <a href="#features">Recursos</a>
          <a href="#como-funciona">Como funciona</a>
          <a href="#equipe">Equipe</a>
          <a
            className="btn btn-primary btn-sm"
            href="http://4.229.233.225:3333/docs"
            target="_blank"
            rel="noopener noreferrer"
          >
            API Docs
          </a>
        </nav>
      </header>

      <main>
        <section className="hero container">
          <div className="hero-copy">
            <span className="badge">PI · FATEC Franca · DSM G08 · 2026</span>
            <h1>
              Hábitos saudáveis,{" "}
              <span className="text-gradient">passo a passo</span>
            </h1>
            <p>
              O Vitalis analisa sua rotina com Machine Learning e sugere um plano
              personalizado de alimentação, lembretes e bem-estar — sem substituir
              consulta médica.
            </p>
            <div className="actions">
              <a className="btn btn-primary" href="#como-funciona">
                Ver como funciona
              </a>
              <a className="btn btn-secondary" href="#mockups">
                Ver o app
              </a>
            </div>
            <ul className="hero-stats">
              <li>
                <strong>ML</strong>
                <span>Logistic Regression</span>
              </li>
              <li>
                <strong>K-Means</strong>
                <span>Clusterização</span>
              </li>
              <li>
                <strong>Gemini</strong>
                <span>Cardápio IA</span>
              </li>
            </ul>
          </div>

          <div className="hero-visual">
            <div className="hero-glow" />
            <PhoneMockup screen="home" className="phone-hero" />
          </div>
        </section>

        <section id="mockups" className="mockups-section">
          <div className="container mockups-inner">
            <div className="section-head">
              <span className="eyebrow">Preview do app</span>
              <h2>Seu bem-estar na palma da mão</h2>
              <p>
                App Flutter para Android e iOS, conectado à API na nuvem com
                modelos de IA treinados para o seu perfil.
              </p>
            </div>
            <div className="mockups-grid">
              <div className="mockup-block">
                <PhoneMockup screen="home" />
                <h3>Home personalizada</h3>
                <p>Perfil, score, lembretes do dia e recomendações ativas.</p>
              </div>
              <div className="mockup-block mockup-block--offset">
                <PhoneMockup screen="plan" />
                <h3>Plano alimentar</h3>
                <p>Cardápio com alimentos e porções + registro do que comeu.</p>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="features-section container">
          <div className="section-head section-head--center">
            <span className="eyebrow">Recursos</span>
            <h2>Tudo que o Vitalis oferece</h2>
          </div>
          <div className="features">
            {features.map((item) => (
              <article className="card" key={item.title}>
                <span className="card-icon">{item.icon}</span>
                <h3>{item.title}</h3>
                <p>{item.text}</p>
              </article>
            ))}
          </div>
        </section>

        <section id="como-funciona" className="steps-section">
          <div className="container">
            <div className="section-head section-head--center">
              <span className="eyebrow">Como funciona</span>
              <h2>Três passos para começar</h2>
            </div>
            <ol className="steps">
              {steps.map((step) => (
                <li className="step" key={step.n}>
                  <span className="step-n">{step.n}</span>
                  <div>
                    <h3>{step.title}</h3>
                    <p>{step.text}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </section>

        <section className="cta-section container">
          <div className="cta-card">
            <div>
              <h2>Projeto Integrador · Aprendizagem de Máquina</h2>
              <p>
                Monorepo com API Node.js, app Flutter, serviço ML em Python e
                esta landing em Next.js — hospedado em VM Azure para demo e
                apresentação.
              </p>
            </div>
            <a
              className="btn btn-primary"
              href="http://4.229.233.225:3333/docs"
              target="_blank"
              rel="noopener noreferrer"
            >
              Explorar Swagger
            </a>
          </div>
        </section>

        <section id="equipe" className="team-section container">
          <div className="section-head section-head--center">
            <span className="eyebrow">Equipe G08</span>
            <h2>Quem desenvolveu</h2>
          </div>
          <ul className="team">
            <li>Vitor Siqueira Simeao</li>
            <li>Uriel Monte Paz de Araujo</li>
            <li>Gabriel Aleixo</li>
            <li>Dimerson Ferreira</li>
          </ul>
        </section>

        <section className="container disclaimer">
          O Vitalis oferece sugestões de bem-estar com base em Machine Learning.
          Não realiza diagnóstico médico nem substitui orientação de profissionais
          de saúde.
        </section>
      </main>

      <footer className="site-footer container">
        <span>Vitalis · DSM P5 G08 · FATEC Franca · 2026</span>
        <a href="/admin">Admin</a>
      </footer>
    </>
  );
}