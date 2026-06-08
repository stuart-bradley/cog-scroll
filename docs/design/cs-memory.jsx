// cs-memory.jsx — Working Memory / Spatial: Digit Span + Spatial Grid (Corsi).

(function () {
  const { useState, useRef, useEffect, T, Label, Shape, Bloom, Pulse } = CS;

  function accDeltaSpan(key, span) {
    const last = CS.store.get(key, null); CS.store.set(key, span);
    if (last == null) return null;
    return { dir: span >= last ? 'up' : 'down', text: `${span >= last ? '+' : ''}${span - last} vs last` };
  }

  // ── DIGIT SPAN ──────────────────────────────────────────────────────────────
  function DigitSpan({ onExit }) {
    const TRIALS = 6;
    const [ui, setUi] = useState({ phase: 'intro', stage: 'show', L: 4, digit: null, input: [], fb: null, trial: 0, summary: null });
    const eng = useRef(null);
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        L: 4, seq: [], input: [], trial: 0, cc: 0, cf: 0, best: 0, resolved: false, timers: [], phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.trial = 0; this.cc = 0; this.cf = 0; this.best = 0; this.L = 4; this.phase = 'playing'; up({ phase: 'playing' }); this.present(); },
        present() {
          this.clear(); this.resolved = false; this.input = [];
          this.seq = Array.from({ length: this.L }, () => Math.floor(Math.random() * 10));
          up({ stage: 'show', input: [], fb: null, digit: null, L: this.L, trial: this.trial });
          let t = 350;
          this.seq.forEach((d) => {
            this.timers.push(setTimeout(() => up({ digit: d }), t));
            this.timers.push(setTimeout(() => up({ digit: null }), t + 720));
            t += 980;
          });
          this.timers.push(setTimeout(() => up({ stage: 'recall' }), t));
        },
        pad(d) {
          if (this.resolved || uiRef.current.stage !== 'recall') return;
          this.input.push(d); up({ input: this.input.slice() });
          if (this.input.length >= this.L) this.judge();
        },
        judge() {
          this.resolved = true; this.clear();
          const correct = this.input.join('') === this.seq.join('');
          if (correct) { this.best = Math.max(this.best, this.L); this.cc++; this.cf = 0; if (this.cc >= 2) { this.L++; this.cc = 0; } }
          else { this.cf++; this.cc = 0; if (this.cf >= 2 && this.L > 3) { this.L--; this.cf = 0; } }
          up({ fb: correct ? 'hit' : 'wrong' });
          this.trial++;
          this.timers.push(setTimeout(() => { if (this.trial >= TRIALS) this.finish(); else this.present(); }, 950));
        },
        finish() { this.clear(); const norm = CS.normalize('digit-span', this.best); CS.recordResult('Working Memory', norm); this.phase = 'round'; up({ phase: 'round', summary: { span: this.best, delta: accDeltaSpan('digit-span', this.best) } }); },
      };
    }
    const e = eng.current;
    const uiRef = useRef(ui); uiRef.current = ui;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';

    return (
      <>
        <CS.TopBar onBack={onExit} title="Digit Span" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.trial + 1}/{TRIALS}</Label> : null} />
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote="Forward order"
            legend={<div style={{ display: 'flex', gap: 10 }}>{[4, 1, 9].map((d, i) => <span key={i} style={{ fontFamily: T.font, fontSize: 30, fontWeight: 600, color: i === 1 ? T.fg : T.sub }}>{d}</span>)}</div>}>
            Watch the digits, then tap them back in <b style={{ fontWeight: 600 }}>the same order</b>.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.span} caption="Best span" sub="Digits recalled" delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && (
          <>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              {ui.stage === 'show' && <div key={ui.digit + '' + ui.trial + Math.random()} style={{ fontFamily: T.font, fontSize: 132, fontWeight: 600, color: T.fg, fontVariantNumeric: 'tabular-nums', minHeight: 140, animation: ui.digit != null ? 'csPop .18s ease-out' : 'none' }}>{ui.digit != null ? ui.digit : ''}</div>}
              {ui.stage === 'recall' && (
                <div className={ui.fb === 'wrong' ? 'cs-shake' : ''} style={{ position: 'relative', display: 'flex', gap: 12, alignItems: 'center', justifyContent: 'center' }}>
                  {ui.fb === 'hit' && <Bloom size={150} />}
                  {Array.from({ length: ui.L }).map((_, i) => (
                    <span key={i} style={{ fontFamily: T.font, fontSize: 40, fontWeight: 600, color: i < ui.input.length ? T.fg : T.faint, fontVariantNumeric: 'tabular-nums', width: 26, textAlign: 'center' }}>{i < ui.input.length ? ui.input[i] : '·'}</span>
                  ))}
                </div>
              )}
            </div>
            {ui.stage === 'recall' && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, padding: '0 40px 36px' }}>
                {[1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, null].map((d, i) => d == null
                  ? <div key={i} />
                  : <button key={i} onClick={() => e.pad(d)} style={{ height: 62, borderRadius: 14, border: `1.5px solid ${T.line}`, background: T.bg, fontFamily: T.font, fontSize: 24, fontWeight: 600, color: T.fg, cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>{d}</button>)}
              </div>
            )}
            {ui.stage === 'show' && <div style={{ padding: '0 0 40px', display: 'flex', justifyContent: 'center' }}><Label color={T.faint}>Remember</Label></div>}
          </>
        )}
      </>
    );
  }

  // ── SPATIAL GRID (CORSI) ────────────────────────────────────────────────────
  function Corsi({ onExit, baseline }) {
    const TRIALS = baseline && baseline.trials ? baseline.trials : 6, N = 4; // 4×4 grid
    const [ui, setUi] = useState({ phase: 'intro', stage: 'show', L: 3, lit: -1, taps: [], fb: null, trial: 0, summary: null, bad: -1 });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        L: 3, seq: [], pos: 0, trial: 0, cc: 0, cf: 0, best: 0, resolved: false, timers: [], phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        start() { this.trial = 0; this.cc = 0; this.cf = 0; this.best = 0; this.L = 3; this.phase = 'playing'; up({ phase: 'playing' }); this.present(); },
        present() {
          this.clear(); this.resolved = false; this.pos = 0;
          const cells = [...Array(N * N).keys()]; const seq = [];
          for (let i = 0; i < this.L; i++) { const idx = Math.floor(Math.random() * cells.length); seq.push(cells.splice(idx, 1)[0]); }
          this.seq = seq;
          up({ stage: 'show', taps: [], fb: null, lit: -1, bad: -1, L: this.L, trial: this.trial });
          let t = 400;
          seq.forEach((c) => { this.timers.push(setTimeout(() => up({ lit: c }), t)); this.timers.push(setTimeout(() => up({ lit: -1 }), t + 480)); t += 640; });
          this.timers.push(setTimeout(() => up({ stage: 'recall' }), t));
        },
        tapCell(c) {
          if (this.resolved || uiRef.current.stage !== 'recall') return;
          if (c === this.seq[this.pos]) {
            this.pos++; const taps = uiRef.current.taps.concat(c); up({ taps, lit: c });
            this.timers.push(setTimeout(() => up({ lit: -1 }), 180));
            if (this.pos >= this.L) this.judge(true);
          } else { this.judge(false, c); }
        },
        judge(correct, badCell) {
          this.resolved = true; this.clear();
          if (correct) { this.best = Math.max(this.best, this.L); this.cc++; this.cf = 0; if (this.cc >= 2) { this.L++; this.cc = 0; } }
          else { this.cf++; this.cc = 0; if (this.cf >= 2 && this.L > 2) { this.L--; this.cf = 0; } }
          up({ fb: correct ? 'hit' : 'wrong', bad: correct ? -1 : badCell });
          this.trial++;
          this.timers.push(setTimeout(() => { if (this.trial >= TRIALS) this.finish(); else this.present(); }, correct ? 850 : 1000));
        },
        finish() { this.clear(); const norm = CS.normalize('corsi-span', this.best); CS.recordResult('Spatial Reasoning', norm); if (blRef.current) { CS.store.set('corsi-span', this.best); blRef.current.onDone(norm); return; } this.phase = 'round'; up({ phase: 'round', summary: { span: this.best, delta: accDeltaSpan('corsi-span', this.best) } }); },
      };
    }
    const e = eng.current;
    const uiRef = useRef(ui); uiRef.current = ui;
    useEffect(() => () => e.clear(), []);
    const playing = ui.phase === 'playing';

    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="Spatial Grid" right={playing ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.trial + 1}/{TRIALS}</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.start()} footnote="Watch, then repeat"
            legend={<div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 5 }}>{[0, 1, 0, 0, 0, 1, 1, 0, 0].map((v, i) => <div key={i} style={{ width: 13, height: 13, borderRadius: 3, background: v ? T.fg : T.line }} />)}</div>}>
            The squares light up in order. Tap them back in <b style={{ fontWeight: 600 }}>the same sequence</b>.
          </CS.Intro>
        )}
        {ui.phase === 'round' && <CS.RoundEnd value={ui.summary.span} caption="Best span" sub="Cells recalled" delta={ui.summary.delta} onContinue={() => e.start()} />}
        {playing && (
          <>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              {ui.fb === 'hit' && <Pulse size={250} radius={18} />}
              <div className={ui.fb === 'wrong' ? 'cs-shake' : ''} style={{ display: 'grid', gridTemplateColumns: `repeat(${N}, 1fr)`, gap: 12 }}>
                {[...Array(N * N).keys()].map((c) => {
                  const lit = ui.lit === c, bad = ui.bad === c, tapped = ui.stage === 'recall' && ui.taps.includes(c);
                  return (
                    <button key={c} onClick={() => e.tapCell(c)} disabled={ui.stage !== 'recall'}
                      style={{ width: 66, height: 66, borderRadius: 14, border: bad ? `2px solid ${T.fg}` : `1.5px solid ${T.line}`, background: (lit || tapped) ? T.fg : bad ? T.bg : T.panel, cursor: ui.stage === 'recall' ? 'pointer' : 'default', transition: 'background .08s', WebkitTapHighlightColor: 'transparent', position: 'relative' }}>
                      {bad && <span style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CS.Cross c={T.fg} s={20} /></span>}
                    </button>
                  );
                })}
              </div>
            </div>
            <div style={{ padding: '0 0 40px', display: 'flex', justifyContent: 'center' }}><Label color={T.faint}>{ui.stage === 'show' ? 'Watch' : 'Repeat the sequence'}</Label></div>
          </>
        )}
      </>
    );
  }

  CS.register({ id: 'digitspan', name: 'Digit Span', domain: 'Working Memory', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30"><text x="15" y="20" textAnchor="middle" fontFamily="'Space Grotesk'" fontSize="15" fontWeight="600" fill={T.fg}>49</text></svg>, Component: DigitSpan });
  CS.register({ id: 'corsi', name: 'Spatial Grid', domain: 'Spatial Reasoning', Icon: () => <svg width="30" height="30" viewBox="0 0 30 30"><rect x="6" y="6" width="7" height="7" rx="1.5" fill={T.faint} /><rect x="17" y="6" width="7" height="7" rx="1.5" fill={T.fg} /><rect x="6" y="17" width="7" height="7" rx="1.5" fill={T.fg} /><rect x="17" y="17" width="7" height="7" rx="1.5" fill={T.faint} /></svg>, Component: Corsi });
})();
