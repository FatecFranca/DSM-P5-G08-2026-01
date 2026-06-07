type Screen = "home" | "plan";

interface PhoneMockupProps {
  screen?: Screen;
  className?: string;
}

export function PhoneMockup({ screen = "home", className = "" }: PhoneMockupProps) {
  return (
    <div className={`phone ${className}`.trim()} aria-hidden="true">
      <div className="phone-bezel">
        <div className="phone-notch" />
        <div className="phone-screen">
          <div className="mock-status">
            <span>9:41</span>
            <span className="mock-status-icons">● ● ▮</span>
          </div>
          <div className="mock-appbar">
            <span className="mock-appbar-title">Vitalis</span>
            <span className="mock-appbar-icon">♡</span>
          </div>

          {screen === "home" ? <HomeScreen /> : <PlanScreen />}

          <nav className="mock-nav">
            <span className="active">Início</span>
            <span>Plano</span>
            <span>Lembretes</span>
            <span>Perfil</span>
          </nav>
        </div>
      </div>
      <div className="phone-shadow" />
    </div>
  );
}

function HomeScreen() {
  return (
    <div className="mock-content">
      <div className="mock-chip mock-chip--ok">IA conectada</div>
      <div className="mock-card mock-card--profile">
        <p className="mock-label">Seu perfil</p>
        <h3>Equilibrado</h3>
        <div className="mock-score">
          <span>Score</span>
          <strong>72</strong>
        </div>
        <div className="mock-bar">
          <div className="mock-bar-fill" style={{ width: "72%" }} />
        </div>
      </div>
      <div className="mock-row">
        <div className="mock-mini">
          <span>Pontos</span>
          <strong>120</strong>
        </div>
        <div className="mock-mini">
          <span>Nível</span>
          <strong>3</strong>
        </div>
      </div>
      <p className="mock-section">Lembretes de hoje</p>
      <div className="mock-list-item">
        <span className="mock-dot mock-dot--water" />
        <div>
          <strong>Beber água</strong>
          <small>09:00 · 2 copos</small>
        </div>
      </div>
      <div className="mock-list-item">
        <span className="mock-dot mock-dot--meal" />
        <div>
          <strong>Almoço leve</strong>
          <small>12:30 · Salada + proteína</small>
        </div>
      </div>
    </div>
  );
}

function PlanScreen() {
  return (
    <div className="mock-content">
      <div className="mock-card mock-card--plan">
        <p className="mock-label">Cardápio do dia</p>
        <h3>Café da manhã</h3>
        <ul className="mock-meals">
          <li>
            <span>Ovos mexidos</span>
            <em>2 un.</em>
          </li>
          <li>
            <span>Pão integral</span>
            <em>1 fatia</em>
          </li>
          <li>
            <span>Fruta</span>
            <em>1 porção</em>
          </li>
        </ul>
      </div>
      <div className="mock-card mock-card--plan mock-card--accent">
        <p className="mock-label">Almoço</p>
        <h3>Prato colorido</h3>
        <ul className="mock-meals">
          <li>
            <span>Vegetais</span>
            <em>50%</em>
          </li>
          <li>
            <span>Proteína</span>
            <em>120 g</em>
          </li>
        </ul>
      </div>
      <div className="mock-input-row">
        <span>O que comi hoje…</span>
        <button type="button" className="mock-add">
          +
        </button>
      </div>
    </div>
  );
}