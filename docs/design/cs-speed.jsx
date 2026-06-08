// cs-speed.jsx — Processing Speed. Reaction Time.

(function () {
  const { useState, useRef, useEffect, T, Label, Shape } = CS;
  const TRIALS = 5;

  function Icon() {
    return (
      <svg width="30" height="30" viewBox="0 0 30 30" fill="none">
        <circle cx="15" cy="15" r="5" fill={T.fg} />
        <circle cx="15" cy="15" r="11" stroke={T.faint} strokeWidth="2" />
      </svg>
    );
  }

  function Reaction({ onExit, baseline }) {
    const [ui, setUi] = useState({ phase: 'intro', stage: 'wait', ms: null, trial: 0, summary: null });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        times: [], trial: 0, t0: 0, timers: [], phase: 'intro', stage: 'wait', last: CS.store.get('rt-avg', null),
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        total: TRIALS,
        start() { this.total = blRef.current && blRef.current.trials ? blRef.current.trials : TRIALS; this.times = []; this.trial = 0; this.phase = 'playing'; up({ phase: 'playing' }); this.next(); },
        next() {
          this.clear(); this.stage = 'wait'; up({ stage: 'wait', ms: null, trial: this.trial });
          this.timers.push(setTimeout(() => { this.stage = 'ready'; this.t0 = performance.now(); up({ stage: 'ready' }); }, 1100 + Math.random() * 2600));
        },
        tap() {
          if (this.phase !== 'playing') return;
          if (this.stage === 'wait') { this.clear(); this.stage = 'tooSoon'; up({ stage: 'tooSoon' }); this.timers.push(setTimeout(() => this.next(), 950)); return; }
          if (this.stage === 'ready') {
            const ms = Math.round(performance.now() - this.t0);
            this.times.push(ms); this.stage = 'result'; up({ stage: 'result', ms });
            this.trial += 1;
            this.timers.push(setTimeout(() => { if (this.trial >= this.total) this.finish(); else this.next(); }, 1000));
          }
        },
        finish() {
          this.clear();
          const avg = Math.round(this.times.reduce((a, b) => a + b, 0) / this.times.length);
          const best = Math.min(...this.times);
          const delta = this.last == null ? null : (avg <= this.last ? { dir: 'up', text: `${this.last - avg}ms faster` } : { dir: 'down', text: `${avg - this.last}ms slower` });
          this.last = avg; CS.store.set('rt-avg', avg);
          const norm = CS.normalize('rt-avg', avg); CS.recordResult('Processing Speed', norm);
          if (blRef.current) { blRef.current.onDone(norm); return; }
          this.phase = 'round'; up({ phase: 'round', summary: { avg, best, delta } });
        },
      };
    }
    const e = eng.current;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';
    const total = baseline && baseline.trials ? baseline.trials : TRIALS;

    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="Reaction Time" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.trial + 1}/{total}</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} startLabel="Begin" footnote={`${total} taps`}
            legend={<Shape id={0} size={40} color={T.sub} />}>
            When the shape appears, tap <b style={{ fontWeight: 600 }}>as fast as you can</b>. Don&rsquo;t jump the gun.
          </CS.Intro>
        )}
        {ui.phase === 'round' && (
          <CS.RoundEnd value={ui.summary.avg} caption="Avg · ms" sub={`Best ${ui.summary.best} ms`} delta={ui.summary.delta} onContinue={() => e.start()} continueLabel="Again" />
        )}
        {playing && (
          <div onClick={() => e.tap()} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', gap: 26, padding: '0 30px 60px' }}>
            {ui.stage === 'wait' && <Label color={T.faint} size={14}>Wait for it…</Label>}
            {ui.stage === 'ready' && <div style={{ animation: 'csPop .12s ease-out' }}><Shape id={0} size={200} /></div>}
            {ui.stage === 'result' && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, animation: 'csFade .2s ease-out' }}>
                <div style={{ fontFamily: T.font, fontSize: 64, fontWeight: 600, color: T.fg, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{ui.ms}</div>
                <Label>ms</Label>
              </div>
            )}
            {ui.stage === 'tooSoon' && (
              <div className="cs-shake" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
                <Shape id={0} size={200} outline />
                <Label color={T.fg} style={{ letterSpacing: '0.2em' }}>Too soon</Label>
              </div>
            )}
          </div>
        )}
      </>
    );
  }

  CS.register({ id: 'reaction', name: 'Reaction Time', domain: 'Processing Speed', Icon, Component: Reaction });
})();
