// cs-session.jsx — adaptive daily "Today" set. Picks 4–5 games, weighting
// weak domains (×2 below average, ×3 bottom of range), never repeating a game,
// favouring distinct domains. Runs back-to-back (full rounds, auto-advance),
// persists per calendar day, feeds the dashboard via each game's recordResult.

(function () {
  const { useState, T, Label } = CS;

  const today = () => new Date().toISOString().slice(0, 10);

  // domain → selection weight from current scores
  function weights() {
    const scores = CS.domainScores();
    const vals = CS.DOMAINS.map((d) => scores[d]).filter((v) => v != null);
    const mean = vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : 50;
    const min = vals.length ? Math.min(...vals) : 0;
    const max = vals.length ? Math.max(...vals) : 100;
    const range = Math.max(max - min, 1);
    const w = {};
    CS.DOMAINS.forEach((d) => {
      const s = scores[d];
      if (s == null) { w[d] = 2; return; }          // unmeasured → gently encouraged
      if (s <= min + range * 0.25) w[d] = 3;          // bottom of personal range
      else if (s < mean) w[d] = 2;                    // below average
      else w[d] = 1;                                  // maintenance
    });
    return w;
  }

  function pick() {
    const w = weights();
    const size = Math.random() < 0.5 ? 4 : 5;         // vary 4–5
    const pool = CS.DOMAINS.slice();
    const chosen = [];
    while (chosen.length < size && pool.length) {
      const total = pool.reduce((a, d) => a + w[d], 0);
      let r = Math.random() * total, idx = 0;
      for (; idx < pool.length - 1; idx++) { r -= w[pool[idx]]; if (r <= 0) break; }
      chosen.push(pool.splice(idx, 1)[0]);
    }
    const byDomain = {};
    CS.games.forEach((g) => { (byDomain[g.domain] = byDomain[g.domain] || []).push(g); });
    return chosen.map((d) => {
      const list = byDomain[d] || [];
      const g = list[Math.floor(Math.random() * list.length)];
      return g ? { id: g.id, domain: d, focus: w[d] >= 2 } : null;
    }).filter(Boolean);
  }

  function getToday() {
    let s = CS.store.get('session', null);
    if (!s || s.date !== today() || !s.steps || !s.steps.length) {
      const steps = pick();
      s = { date: today(), steps, done: steps.map(() => false) };
      CS.store.set('session', s);
    }
    if (!s.done || s.done.length !== s.steps.length) {
      s.done = s.steps.map((_, i) => (s.done && s.done[i]) || false);
      CS.store.set('session', s);
    }
    return s;
  }

  function markDone(i) {
    const s = getToday();
    if (!s.done[i]) { s.done[i] = true; CS.store.set('session', s); }
    return s;
  }

  function progress() { const s = getToday(); return { total: s.steps.length, done: s.done.filter(Boolean).length }; }

  // ── guided runner ────────────────────────────────────────────────────────────
  function Header({ idx, total, step, onSkip, onExit }) {
    const pad = (x) => String(x).padStart(2, '0');
    const g = CS.games.find((x) => x.id === step.id);
    return (
      <div style={{ padding: '30px 24px 0', flex: '0 0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button onClick={onExit} aria-label="Exit session" style={{ border: 'none', background: 'transparent', padding: 4, margin: -4, cursor: 'pointer', display: 'flex', WebkitTapHighlightColor: 'transparent' }}>
              <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={T.fg} strokeWidth="2" strokeLinecap="round"><path d="M4 4l10 10M14 4L4 14" /></svg>
            </button>
            <Label color={T.sub}>Today · {pad(idx + 1)} / {pad(total)}</Label>
          </div>
          <button onClick={onSkip} style={{ border: 'none', background: 'transparent', cursor: 'pointer', padding: '6px 0', WebkitTapHighlightColor: 'transparent' }}><Label color={T.faint}>Skip</Label></button>
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 16, alignItems: 'center' }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < idx ? T.fg : i === idx ? T.sub : T.line }} />
          ))}
        </div>
        {step.focus && <div style={{ marginTop: 12 }}><Label color={T.faint} size={10}>Focus · {step.domain}</Label></div>}
      </div>
    );
  }

  function Complete({ doneCount, onContinue }) {
    return (
      <>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14, animation: 'csFade .35s ease-out', padding: '0 36px' }}>
          <Label color={T.sub}>Session complete</Label>
          <div style={{ fontFamily: T.font, fontSize: 92, fontWeight: 600, lineHeight: 0.9, letterSpacing: '-0.03em', color: T.fg, fontVariantNumeric: 'tabular-nums' }}>{doneCount}</div>
          <Label>{doneCount === 1 ? 'game played' : 'games played'}</Label>
          <div style={{ marginTop: 10, fontFamily: T.font, fontSize: 15, fontWeight: 500, color: T.sub, textAlign: 'center', textWrap: 'pretty', lineHeight: 1.45, maxWidth: 280 }}>Nice work. Your progress is updated — see it any time in Settings.</div>
        </div>
        <CS.WideButton label="Back to Today" onClick={onContinue} />
      </>
    );
  }

  function Session({ onExit, onComplete }) {
    const sess = getToday();
    const steps = sess.steps;
    const first = sess.done.findIndex((x) => !x);
    const [idx, setIdx] = useState(first < 0 ? steps.length : first);
    const [played, setPlayed] = useState(0);

    if (idx >= steps.length) {
      const doneCount = getToday().done.filter(Boolean).length;
      return <Complete doneCount={doneCount} onContinue={onComplete} />;
    }

    const advance = (didPlay) => {
      if (didPlay) { markDone(idx); setPlayed((p) => p + 1); }
      setIdx((i) => i + 1);
    };

    const step = steps[idx];
    const game = CS.games.find((g) => g.id === step.id);
    const baseline = { index: idx, total: steps.length, domain: step.domain, focus: step.focus, onDone: () => advance(true), onSkip: () => advance(false) };

    return (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <Header idx={idx} total={steps.length} step={step} onSkip={() => advance(false)} onExit={onExit} />
        <div key={step.id + idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          {game ? <game.Component onExit={onExit} baseline={baseline} /> : null}
        </div>
      </div>
    );
  }

  Object.assign(window.CS, { Session, getTodaySession: getToday, todayProgress: progress });
})();
