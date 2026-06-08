// cs-onboarding.jsx — first-run baseline. One short game per domain (~5 min),
// keeps each game's own Intro, auto-advances, skippable per game, then reveals
// the seeded radar. No mid-flow resume (restarts clean each time).

(function () {
  const { useState, useEffect, T, Label, Shape } = CS;

  // One representative, gentle game per domain — abbreviated to stay under 5 min.
  const BASELINE_SET = [
    { id: 'reaction', domain: 'Processing Speed', trials: 5 },
    { id: 'flanker', domain: 'Sustained Attention', trials: 10 },
    { id: 'gonogo', domain: 'Attention & Inhibition', trials: 12 },
    { id: 'nback', domain: 'Working Memory', trials: 10 },
    { id: 'corsi', domain: 'Spatial Reasoning', trials: 4 },
    { id: 'trails', domain: 'Mental Flexibility', points: 8 },
  ];

  const solidPill = { height: 64, width: '100%', borderRadius: 999, background: T.fg, color: T.bg, fontFamily: T.font, fontSize: 13.5, fontWeight: 600, letterSpacing: '0.22em', textTransform: 'uppercase', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', WebkitTapHighlightColor: 'transparent', transition: 'transform .08s' };

  function Welcome({ onStart, onSkip }) {
    return (
      <>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 42px', gap: 26, animation: 'csFade .3s ease-out' }}>
          <div style={{ display: 'flex', gap: 9 }}>{[0, 1, 2, 3, 4, 5].map((i) => <Shape key={i} id={i} size={20} color={T.sub} />)}</div>
          <div style={{ fontFamily: T.font, fontSize: 28, fontWeight: 600, letterSpacing: '-0.02em', textAlign: 'center', lineHeight: 1.1, color: T.fg }}>Find your baseline</div>
          <div style={{ fontFamily: T.font, fontSize: 17, fontWeight: 500, lineHeight: 1.5, color: T.sub, textAlign: 'center', textWrap: 'pretty' }}>
            Six short games, one for each cognitive domain. About five minutes. This maps where you&rsquo;re starting from, so each day can focus where it helps most.
          </div>
          <Label color={T.faint}>6 games · ~5 min · skippable</Label>
        </div>
        <div style={{ padding: '0 30px 34px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, flex: '0 0 auto' }}>
          <button onClick={onStart} style={solidPill}
            onMouseDown={(e) => (e.currentTarget.style.transform = 'scale(0.98)')}
            onMouseUp={(e) => (e.currentTarget.style.transform = '')}
            onMouseLeave={(e) => (e.currentTarget.style.transform = '')}>Begin</button>
          <button onClick={onSkip} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 12, WebkitTapHighlightColor: 'transparent' }}><Label color={T.sub}>Maybe later</Label></button>
        </div>
      </>
    );
  }

  function Complete({ onContinue }) {
    const scores = CS.domainScores();
    const measured = Object.values(scores).filter((v) => v != null).length;
    return (
      <>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 28px', gap: 4, animation: 'csFade .3s ease-out' }}>
          <Label color={T.sub}>Baseline complete</Label>
          <div style={{ fontFamily: T.font, fontSize: 25, fontWeight: 600, letterSpacing: '-0.02em', textAlign: 'center', color: T.fg, marginTop: 6 }}>Your starting map</div>
          <div style={{ marginTop: 16 }}><CS.Radar scores={scores} size={258} reveal /></div>
          <div style={{ fontFamily: T.font, fontSize: 14.5, fontWeight: 500, color: T.sub, textAlign: 'center', textWrap: 'pretty', marginTop: 14, maxWidth: 300, lineHeight: 1.45 }}>
            {measured >= 6
              ? 'All six domains seeded. From here we track only your own trajectory — never anyone else\u2019s.'
              : `${measured} of 6 domains seeded. Play the skipped games any time to fill in the rest.`}
          </div>
        </div>
        <CS.WideButton label="Done" onClick={onContinue} />
      </>
    );
  }

  function Header({ step, total, onSkip, onExit }) {
    const pad = (x) => String(x).padStart(2, '0');
    return (
      <div style={{ padding: '30px 24px 0', flex: '0 0 auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button onClick={onExit} aria-label="Exit baseline" style={{ border: 'none', background: 'transparent', padding: 4, margin: -4, cursor: 'pointer', display: 'flex', WebkitTapHighlightColor: 'transparent' }}>
              <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={T.fg} strokeWidth="2" strokeLinecap="round"><path d="M4 4l10 10M14 4L4 14" /></svg>
            </button>
            <Label color={T.sub}>Baseline · {pad(step + 1)} / {pad(total)}</Label>
          </div>
          <button onClick={onSkip} style={{ border: 'none', background: 'transparent', cursor: 'pointer', padding: '6px 0', WebkitTapHighlightColor: 'transparent' }}><Label color={T.faint}>Skip</Label></button>
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 16 }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: i < step ? T.fg : i === step ? T.sub : T.line }} />
          ))}
        </div>
      </div>
    );
  }

  function Baseline({ onExit, onComplete }) {
    const [stage, setStage] = useState('welcome'); // welcome | playing | done
    const [step, setStep] = useState(0);
    useEffect(() => { CS.store.set('baselinePrompted', true); }, []);

    const advance = () => {
      setStep((s) => {
        const next = s + 1;
        if (next >= BASELINE_SET.length) { CS.store.set('onboarded', true); setStage('done'); return s; }
        return next;
      });
    };

    if (stage === 'welcome') return <Welcome onStart={() => setStage('playing')} onSkip={onExit} />;
    if (stage === 'done') return <Complete onContinue={onComplete} />;

    const cfg = BASELINE_SET[step];
    const game = CS.games.find((g) => g.id === cfg.id);
    const baseline = { index: step, total: BASELINE_SET.length, domain: cfg.domain, trials: cfg.trials, points: cfg.points, onDone: advance, onSkip: advance };

    return (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <Header step={step} total={BASELINE_SET.length} onSkip={advance} onExit={onExit} />
        <div key={cfg.id} style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          {game ? <game.Component onExit={onExit} baseline={baseline} /> : null}
        </div>
      </div>
    );
  }

  Object.assign(window.CS, { Baseline, BASELINE_SET });
})();
