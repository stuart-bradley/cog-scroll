// cs-app.jsx — Stage (viewport scaling) + router (home ⇄ game). Mounts.

const { useState, useEffect } = React;

function Stage({ children }) {
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const fit = () => setScale(Math.min(window.innerWidth / 390, window.innerHeight / 844, 1));
    fit(); window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);
  return (
    <div style={{ position: 'fixed', inset: 0, background: '#E4E4E4', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
      <div style={{ position: 'relative', width: 390, height: 844, transform: `scale(${scale})`, background: CS.T.bg, color: CS.T.fg, fontFamily: CS.T.font, display: 'flex', flexDirection: 'column', overflow: 'hidden', boxShadow: '0 30px 90px rgba(0,0,0,0.16)' }}>
        {children}
      </div>
    </div>
  );
}

function App() {
  const [route, setRoute] = useState(null);
  const [paid, setPaid] = useState(CS.trialInfo().purchased);
  const go = (r) => setRoute(r);
  const home = () => setRoute(null);
  let screen;
  if (route === 'baseline') screen = <CS.Baseline onExit={home} onComplete={home} />;
  else if (route === 'session') screen = <CS.Session onExit={home} onComplete={home} />;
  else if (route === 'settings') screen = <CS.Settings onExit={home} go={go} />;
  else if (route === 'dashboard') screen = <CS.Dashboard onExit={home} />;
  else {
    const game = CS.games.find((g) => g.id === route);
    screen = game ? <game.Component onExit={home} /> : <CS.Home onPick={go} />;
  }
  const showPaywall = CS.trialInfo().expired && !paid;
  return (
    <Stage>
      {screen}
      {showPaywall && <CS.Paywall onUnlock={() => { CS.purchase(); setPaid(true); }} />}
    </Stage>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
