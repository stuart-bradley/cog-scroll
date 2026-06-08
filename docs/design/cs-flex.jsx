// cs-flex.jsx — Mental Flexibility: Task Switching + Trail Making.

(function () {
  const { useState, useRef, useEffect, T, Label, Shape, Bloom } = CS;

  function accDelta(key, acc) {
    const last = CS.store.get(key, null); CS.store.set(key, acc);
    if (last == null) return null;
    return { dir: acc >= last ? 'up' : 'down', text: `${acc >= last ? '+' : ''}${acc - last}% vs last round` };
  }

  // ── TASK SWITCHING ──────────────────────────────────────────────────────────
  // Two attributes: SHAPE (circle/square) and FILL (filled/hollow). A banner
  // says which to judge; the two buttons relabel accordingly. Switch = rule
  // changed from the prior trial.
  function TaskSwitch({ onExit }) {
    const ROUND = 20;
    const [ui, setUi] = useState({ phase: 'intro', idx: 0, stim: null, rule: 'shape', fb: null, picked: null });
    const eng = useRef(null);
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        idx: 0, rule: 'shape', results: [], resolved: false, timers: [], phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.idx = 0; this.results = []; this.rule = Math.random() < 0.5 ? 'shape' : 'fill'; this.phase = 'playing'; up({ phase: 'playing' }); this.trial(); },
        trial() {
          this.clear(); this.resolved = false;
          if (this.idx > 0 && Math.random() < 0.5) this.rule = this.rule === 'shape' ? 'fill' : 'shape';
          const stim = { shape: Math.random() < 0.5 ? 0 : 1, filled: Math.random() < 0.5 };
          up({ idx: this.idx, stim, rule: this.rule, fb: null, picked: null });
          this.timers.push(setTimeout(() => { if (!this.resolved) this.resolve(-1); }, 2200));
        },
        pick(choice) {
          if (this.resolved || this.phase !== 'playing') return;
          this.resolve(choice);
        },
        resolve(choice) {
          this.resolved = true; this.clear();
          const s = stimRef.current, r = ruleRef.current;
          let correct = false;
          if (choice >= 0 && s) correct = r === 'shape' ? (choice === s.shape) : (choice === (s.filled ? 0 : 1));
          this.results.push(correct);
          up({ fb: correct ? 'hit' : 'wrong', picked: choice });
          this.timers.push(setTimeout(() => this.advance(), 600));
        },
        advance() { this.clear(); this.idx += 1; if (this.idx >= ROUND) this.finish(); else this.trial(); },
        finish() { this.clear(); const acc = Math.round(this.results.filter(Boolean).length / ROUND * 100); const norm = CS.normalize('switch-acc', acc); CS.recordResult('Mental Flexibility', norm); this.phase = 'round'; up({ phase: 'round', summary: { acc, delta: accDelta('switch-acc', acc) } }); },
      };
    }
    const e = eng.current;
    const stimRef = useRef(ui.stim); stimRef.current = ui.stim;
    const ruleRef = useRef(ui.rule); ruleRef.current = ui.rule;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';
    const labels = ui.rule === 'shape' ? ['Circle', 'Square'] : ['Filled', 'Hollow'];

    return (
      <>
        <CS.TopBar onBack={onExit} title="Task Switching" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.idx + 1}/{ROUND}</Label> : null} />
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote={`${ROUND} trials · the rule keeps changing`}
            legend={<Shape id={0} size={42} />}>
            The banner says what to judge — the shape, or whether it&rsquo;s <b style={{ fontWeight: 600 }}>filled</b>. Watch for the switch.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.acc + '%'} caption="Accuracy" sub={`${ROUND} trials`} delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && ui.stim && (
          <>
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 20 }}>
              <div style={{ padding: '11px 22px', borderRadius: 999, background: T.fg }}>
                <Label color={T.bg} style={{ letterSpacing: '0.22em' }}>Judge · {ui.rule}</Label>
              </div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 16, height: 19 }}>{!ui.fb && <CS.Countdown ms={2200} k={ui.idx} />}</div>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              <div className={ui.fb === 'wrong' ? 'cs-shake' : ''} style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {ui.fb === 'hit' && <Bloom />}
                <Shape id={ui.stim.shape} outline={!ui.stim.filled} />
              </div>
            </div>
            <div style={{ display: 'flex', gap: 14, padding: '0 30px 46px' }}>
              {labels.map((l, i) => (
                <button key={i} onClick={() => e.pick(i)} style={{ flex: 1, height: 64, borderRadius: 999, border: `1.6px solid ${ui.picked === i ? T.fg : T.line}`, background: T.bg, fontFamily: T.font, fontSize: 13.5, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.fg, cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>{l}</button>
              ))}
            </div>
          </>
        )}
      </>
    );
  }

  // ── TRAIL MAKING ────────────────────────────────────────────────────────────
  function genPoints(count, W, H, pad) {
    const cols = 3, rows = Math.ceil(count / cols), cw = W / cols, ch = H / rows;
    const cells = [...Array(cols * rows).keys()];
    for (let i = cells.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [cells[i], cells[j]] = [cells[j], cells[i]]; }
    const pts = [];
    for (let i = 0; i < count; i++) {
      const cell = cells[i], gx = (cell % cols) * cw, gy = Math.floor(cell / cols) * ch;
      pts.push({ x: gx + pad + Math.random() * (cw - 2 * pad), y: gy + pad + Math.random() * (ch - 2 * pad) });
    }
    return pts;
  }

  function Trails({ onExit, baseline }) {
    const COUNT = baseline && baseline.points ? baseline.points : 12, PW = 326, PH = 540, R = 24;
    const [ui, setUi] = useState({ phase: 'intro', pts: [], next: 1, path: [], bad: -1, t: 0, summary: null });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        pts: [], next: 1, path: [], t0: 0, tick: null, badTimer: null, phase: 'intro',
        start() {
          this.pts = genPoints(COUNT, PW, PH, R + 6); this.next = 1; this.path = []; this.t0 = performance.now();
          this.phase = 'playing'; up({ phase: 'playing', pts: this.pts, next: 1, path: [], bad: -1, t: 0 });
          clearInterval(this.tick); this.tick = setInterval(() => up({ t: (performance.now() - this.t0) / 1000 }), 100);
        },
        tap(n) {
          if (this.phase !== 'playing') return;
          if (n === this.next) {
            this.path = this.path.concat(n - 1); this.next++; up({ path: this.path.slice(), next: this.next, bad: -1 });
            if (this.next > COUNT) this.finish();
          } else { clearTimeout(this.badTimer); up({ bad: n - 1 }); this.badTimer = setTimeout(() => up({ bad: -1 }), 360); }
        },
        finish() {
          clearInterval(this.tick); const t = (performance.now() - this.t0) / 1000;
          const norm = CS.normalize('trail-time', t); CS.recordResult('Mental Flexibility', norm);
          const last = CS.store.get('trail-time', null); CS.store.set('trail-time', t);
          if (blRef.current) { blRef.current.onDone(norm); return; }
          const delta = last == null ? null : (t <= last ? { dir: 'up', text: `${(last - t).toFixed(1)}s faster` } : { dir: 'down', text: `${(t - last).toFixed(1)}s slower` });
          this.phase = 'round'; up({ phase: 'round', summary: { t, delta } });
        },
        stop() { clearInterval(this.tick); clearTimeout(this.badTimer); },
      };
    }
    const e = eng.current;
    useEffect(() => () => e.stop(), []);
    const playing = ui.phase === 'playing';

    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="Trail Making" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em', fontVariantNumeric: 'tabular-nums' }}>{ui.t.toFixed(1)}s</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} startLabel="Start" footnote={`Connect 1 – ${COUNT} · against the clock`}
            legend={<svg width="80" height="40" viewBox="0 0 80 40" fill="none"><path d="M10 30 L34 12 L58 28 L72 10" stroke={T.faint} strokeWidth="2" /><circle cx="10" cy="30" r="4" fill={T.fg} /><circle cx="34" cy="12" r="4" fill={T.fg} /><circle cx="58" cy="28" r="4" fill={T.fg} /><circle cx="72" cy="10" r="4" fill={T.fg} /></svg>}>
            Tap the numbers in order, <b style={{ fontWeight: 600 }}>1 to {COUNT}</b>, as fast as you can.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.t.toFixed(1)} caption="Seconds" sub={`${COUNT} targets`} delta={ui.summary.delta} onContinue={() => e.start()} continueLabel="Again" />}
        {playing && (
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ position: 'relative', width: PW, height: PH }}>
              <svg width={PW} height={PH} style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
                <polyline points={ui.path.map((i) => `${ui.pts[i].x},${ui.pts[i].y}`).join(' ')} fill="none" stroke={T.fg} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
              </svg>
              {ui.pts.map((p, i) => {
                const done = i < ui.next - 1, bad = ui.bad === i;
                return (
                  <button key={i} onClick={() => e.tap(i + 1)} className={bad ? 'cs-shake' : ''}
                    style={{ position: 'absolute', left: p.x - R, top: p.y - R, width: 2 * R, height: 2 * R, borderRadius: '50%', border: `2px solid ${T.fg}`, background: done ? T.fg : T.bg, color: done ? T.bg : T.fg, fontFamily: T.font, fontSize: 17, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontVariantNumeric: 'tabular-nums', WebkitTapHighlightColor: 'transparent' }}>
                    {i + 1}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </>
    );
  }

  CS.register({ id: 'taskswitch', name: 'Task Switching', domain: 'Mental Flexibility', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30" fill="none" stroke={T.fg} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M8 11h11l-3-3M22 19H11l3 3" /></svg>, Component: TaskSwitch });
  CS.register({ id: 'trails', name: 'Trail Making', domain: 'Mental Flexibility', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30" fill="none"><path d="M7 22 L14 9 L23 18" stroke={T.faint} strokeWidth="2" /><circle cx="7" cy="22" r="3" fill={T.fg} /><circle cx="14" cy="9" r="3" fill={T.fg} /><circle cx="23" cy="18" r="3" fill={T.fg} /></svg>, Component: Trails });
})();
