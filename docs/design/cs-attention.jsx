// cs-attention.jsx — Attention & Inhibition: Flanker, Go/No-Go, Stroop (B&W).

(function () {
  const { useState, useRef, useEffect, T, Label, Shape, Bloom, Pulse, SHAPE_NAMES } = CS;

  const Arrow = ({ dir, size = 48, color = T.fg, o = 1 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ opacity: o }}>
      <path d={dir === 'L' ? 'M15 5l-7 7 7 7' : 'M9 5l7 7-7 7'} />
    </svg>
  );

  // shared accuracy round-end delta vs stored last accuracy
  function accDelta(key, acc) {
    const last = CS.store.get(key, null); CS.store.set(key, acc);
    if (last == null) return null;
    return { dir: acc >= last ? 'up' : 'down', text: `${acc >= last ? '+' : ''}${acc - last}% vs last round` };
  }

  // ── FLANKER ────────────────────────────────────────────────────────────────
  function Flanker({ onExit, baseline }) {
    const ROUND = baseline && baseline.trials ? baseline.trials : 20;
    const [ui, setUi] = useState({ phase: 'intro', idx: 0, stim: null, fb: null });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        idx: 0, results: [], resolved: false, timers: [], phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.idx = 0; this.results = []; this.phase = 'playing'; up({ phase: 'playing' }); this.trial(); },
        trial() {
          this.clear(); this.resolved = false;
          const dir = Math.random() < 0.5 ? 'L' : 'R';
          const congruent = Math.random() < 0.4;
          up({ idx: this.idx, stim: { dir, congruent }, fb: null });
          this.timers.push(setTimeout(() => { if (!this.resolved) this.resolve(null); }, 1300));
        },
        respond(side) { if (!this.resolved && this.phase === 'playing') this.resolve(side); },
        resolve(side) {
          this.resolved = true; this.clear();
          const correct = side === eng.current._dir();
          this.results.push(correct);
          up({ fb: correct ? 'hit' : 'wrong' });
          this.timers.push(setTimeout(() => this.advance(), 620));
        },
        _dir() { return uiRef.current.stim ? uiRef.current.stim.dir : null; },
        advance() { this.clear(); this.idx += 1; if (this.idx >= ROUND) this.finish(); else this.trial(); },
        finish() { this.clear(); const acc = Math.round(this.results.filter(Boolean).length / ROUND * 100); const norm = CS.normalize('flanker-acc', acc); CS.recordResult('Sustained Attention', norm); if (blRef.current) { CS.store.set('flanker-acc', acc); blRef.current.onDone(norm); return; } this.phase = 'round'; up({ phase: 'round', summary: { acc, delta: accDelta('flanker-acc', acc) } }); },
      };
    }
    const e = eng.current;
    const uiRef = useRef(ui); uiRef.current = ui;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';
    const s = ui.stim;
    const flank = s ? (s.congruent ? s.dir : (s.dir === 'L' ? 'R' : 'L')) : 'L';

    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="Flanker" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.idx + 1}/{ROUND}</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote={`${ROUND} trials`}
            legend={<div style={{ display: 'flex', gap: 4 }}>{['L', 'L', 'R', 'L', 'L'].map((d, i) => <Arrow key={i} dir={d} size={28} color={i === 2 ? T.fg : T.faint} />)}</div>}>
            Tap the side the <b style={{ fontWeight: 600 }}>middle</b> arrow points — ignore the others.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.acc + '%'} caption="Accuracy" sub={`${ROUND} trials`} delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && (
          <>
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 16, height: 19 }}>{!ui.fb && <CS.Countdown ms={1300} k={ui.idx} />}</div>
            <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div className={ui.fb === 'wrong' ? 'cs-shake' : ui.fb === 'hit' ? (s && s.dir === 'R' ? 'cs-surge-r' : 'cs-surge-l') : ''} style={{ display: 'flex', alignItems: 'center', gap: 6, position: 'relative' }}>
                <Arrow dir={flank} /><Arrow dir={flank} /><Arrow dir={s ? s.dir : 'L'} /><Arrow dir={flank} /><Arrow dir={flank} />
              </div>
              {/* tap zones */}
              <button onClick={() => e.respond('L')} aria-label="Left" style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '50%', background: 'transparent', border: 'none', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }} />
              <button onClick={() => e.respond('R')} aria-label="Right" style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: '50%', background: 'transparent', border: 'none', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0 30px 46px', gap: 14 }}>
              {['L', 'R'].map((d) => (
                <button key={d} onClick={() => e.respond(d)} style={{ flex: 1, height: 64, borderRadius: 999, border: `1.6px solid ${T.line}`, background: T.bg, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', WebkitTapHighlightColor: 'transparent' }}>
                  <Arrow dir={d} size={30} />
                </button>
              ))}
            </div>
          </>
        )}
      </>
    );
  }

  // ── GO / NO-GO ───────────────────────────────────────────────────────────--
  function GoNoGo({ onExit, baseline }) {
    const ROUND = baseline && baseline.trials ? baseline.trials : 24, GO = 0, NOGO = 1;
    const [ui, setUi] = useState({ phase: 'intro', idx: 0, shape: null, showing: false, fb: null });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        idx: 0, results: [], resolved: false, timers: [], phase: 'intro', cur: GO,
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.idx = 0; this.results = []; this.phase = 'playing'; up({ phase: 'playing' }); this.trial(); },
        trial() {
          this.clear(); this.resolved = false;
          this.cur = Math.random() < 0.7 ? GO : NOGO;
          up({ idx: this.idx, shape: this.cur, showing: true, fb: null });
          this.timers.push(setTimeout(() => { if (!this.resolved) this.resolve(false); }, 720));
        },
        tap() { if (!this.resolved && this.phase === 'playing') this.resolve(true); },
        resolve(tapped) {
          this.resolved = true; this.clear();
          const isGo = this.cur === GO;
          const correct = tapped ? isGo : !isGo;
          this.results.push(correct);
          up({ fb: correct ? 'hit' : 'wrong' }); // keep shape visible through the motion
          this.timers.push(setTimeout(() => this.advance(), 540));
        },
        advance() {
          this.clear(); up({ showing: false, fb: null });
          this.timers.push(setTimeout(() => { this.idx += 1; if (this.idx >= ROUND) this.finish(); else this.trial(); }, 240));
        },
        finish() { this.clear(); const acc = Math.round(this.results.filter(Boolean).length / ROUND * 100); const norm = CS.normalize('gng-acc', acc); CS.recordResult('Attention & Inhibition', norm); if (blRef.current) { CS.store.set('gng-acc', acc); blRef.current.onDone(norm); return; } this.phase = 'round'; up({ phase: 'round', summary: { acc, delta: accDelta('gng-acc', acc) } }); },
      };
    }
    const e = eng.current;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';
    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="Go / No-Go" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.idx + 1}/{ROUND}</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote={`${ROUND} trials`}
            legend={<div style={{ display: 'flex', gap: 26, alignItems: 'center' }}><div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}><Shape id={GO} size={42} /><Label size={10}>Tap</Label></div><div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}><Shape id={NOGO} size={42} color={T.sub} /><Label size={10}>Hold</Label></div></div>}>
            Tap for the <b style={{ fontWeight: 600 }}>circle</b>. Hold still for the <b style={{ fontWeight: 600 }}>square</b>.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.acc + '%'} caption="Accuracy" sub={`${ROUND} trials`} delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && (
          <div onClick={() => e.tap()} style={{ flex: 1, display: 'flex', flexDirection: 'column', cursor: 'pointer' }}>
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 16, height: 19 }}>{ui.showing && !ui.fb && <CS.Countdown ms={720} k={ui.idx} />}</div>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              {ui.fb === 'hit' && (ui.shape === 1 ? <Pulse size={176} radius={22} /> : <Bloom />)}
              {ui.showing && ui.shape != null && (
                <div key={ui.idx} style={{ animation: ui.fb === 'wrong' ? 'csShake .5s ease-in-out' : ui.fb === 'hit' ? 'none' : 'csPop .14s ease-out' }}>
                  <Shape id={ui.shape} outline={ui.fb === 'wrong'} />
                </div>
              )}
            </div>
            <div style={{ padding: '0 0 40px', display: 'flex', justifyContent: 'center' }}><Label color={T.faint}>Tap anywhere for the circle</Label></div>
          </div>
        )}
      </>
    );
  }

  // ── STROOP (B&W shape-Stroop) ───────────────────────────────────────────────
  function Stroop({ onExit }) {
    const ROUND = 18;
    const [ui, setUi] = useState({ phase: 'intro', idx: 0, stim: null, opts: [], fb: null, picked: null });
    const eng = useRef(null);
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        idx: 0, results: [], resolved: false, timers: [], phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.idx = 0; this.results = []; this.phase = 'playing'; up({ phase: 'playing' }); this.trial(); },
        trial() {
          this.clear(); this.resolved = false;
          const shape = Math.floor(Math.random() * 6);
          const congruent = Math.random() < 0.35;
          let word = shape; if (!congruent) { do { word = Math.floor(Math.random() * 6); } while (word === shape); }
          const opts = [shape]; while (opts.length < 4) { const r = Math.floor(Math.random() * 6); if (!opts.includes(r)) opts.push(r); }
          for (let i = opts.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [opts[i], opts[j]] = [opts[j], opts[i]]; }
          up({ idx: this.idx, stim: { shape, word }, opts, fb: null, picked: null });
        },
        pick(shapeId) {
          if (this.resolved || this.phase !== 'playing') return;
          this.resolved = true; this.clear();
          const correct = shapeId === this._shape();
          this.results.push(correct);
          up({ fb: correct ? 'hit' : 'wrong', picked: shapeId });
          this.timers.push(setTimeout(() => this.advance(), 640));
        },
        _shape() { return stimRef.current ? stimRef.current.shape : -1; },
        advance() { this.clear(); this.idx += 1; if (this.idx >= ROUND) this.finish(); else this.trial(); },
        finish() { this.clear(); const acc = Math.round(this.results.filter(Boolean).length / ROUND * 100); const norm = CS.normalize('stroop-acc', acc); CS.recordResult('Attention & Inhibition', norm); this.phase = 'round'; up({ phase: 'round', summary: { acc, delta: accDelta('stroop-acc', acc) } }); },
      };
    }
    const e = eng.current;
    const stimRef = useRef(ui.stim); stimRef.current = ui.stim;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';
    const s = ui.stim;

    return (
      <>
        <CS.TopBar onBack={onExit} title="Stroop" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.idx + 1}/{ROUND}</Label> : null} />
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote={`${ROUND} trials · tap the shape you see`}
            legend={<div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Shape id={0} size={66} outline /><span style={{ position: 'absolute', color: T.fg, fontFamily: T.font, fontSize: 11, fontWeight: 600, letterSpacing: '0.08em' }}>SQUARE</span></div>}>
            Tap the shape you <b style={{ fontWeight: 600 }}>see</b> — not the word written on it.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.acc + '%'} caption="Accuracy" sub={`${ROUND} trials`} delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && s && (
          <>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              <div className={ui.fb === 'wrong' ? 'cs-shake' : ''} style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {ui.fb === 'hit' && <Bloom size={262} />}
                <Shape id={s.shape} size={232} outline />
                <span style={{ position: 'absolute', color: T.fg, background: T.bg, padding: '3px 8px', borderRadius: 5, fontFamily: T.font, fontSize: 17, fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{SHAPE_NAMES[s.word]}</span>
              </div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', gap: 14, padding: '0 26px 46px' }}>
              {ui.opts.map((o) => (
                <button key={o} onClick={() => e.pick(o)} style={{ width: 64, height: 64, borderRadius: 16, border: `1.6px solid ${ui.picked === o ? T.fg : T.line}`, background: T.bg, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', WebkitTapHighlightColor: 'transparent' }}>
                  <Shape id={o} size={34} />
                </button>
              ))}
            </div>
          </>
        )}
      </>
    );
  }

  CS.register({ id: 'stroop', name: 'Stroop', domain: 'Attention & Inhibition', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30"><circle cx="15" cy="15" r="9" fill={T.fg} /><path d="M11 19 L19 11 M11 11 L19 19" stroke={T.bg} strokeWidth="2" strokeLinecap="round" /></svg>, Component: Stroop });
  CS.register({ id: 'flanker', name: 'Flanker', domain: 'Sustained Attention', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30" fill="none" stroke={T.fg} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M17 9l5 6-5 6" /><path d="M9 9l5 6-5 6" opacity="0.4" /></svg>, Component: Flanker });
  CS.register({ id: 'gonogo', name: 'Go / No-Go', domain: 'Attention & Inhibition', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30"><circle cx="10" cy="15" r="5" fill={T.fg} /><rect x="18" y="10" width="10" height="10" rx="2" fill="none" stroke={T.faint} strokeWidth="2" /></svg>, Component: GoNoGo });
})();
