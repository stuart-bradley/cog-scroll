// cs-nback.jsx — Working Memory. Tap when the shape matches the one N back.

(function () {
  const { useState, useRef, useEffect, T, Shape, Bloom, Label, Shape: S } = CS;
  const SHOW = 1150, FB = 760, CR_BLANK = 360, DEF_ROUND = 20, RATE = 0.32, NSHAPES = 6;

  function Icon() {
    return (
      <svg width="30" height="30" viewBox="0 0 30 30" fill="none">
        <circle cx="7" cy="15" r="3.2" fill={T.faint} />
        <rect x="12.5" y="11.8" width="6.4" height="6.4" rx="1.4" fill={T.faint} />
        <circle cx="24" cy="15" r="3.6" fill={T.fg} />
      </svg>
    );
  }

  function CorrectBurst({ id }) {
    return (
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Bloom />
        <div style={{ animation: 'csPopBig .46s cubic-bezier(.34,1.56,.5,1)' }}><Shape id={id} /></div>
      </div>
    );
  }
  function WrongBurst({ id }) {
    return (
      <div className="cs-shake" style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ position: 'absolute', animation: 'csGhostA .5s ease-out forwards' }}><Shape id={id} outline /></div>
        <div style={{ position: 'absolute', animation: 'csGhostB .5s ease-out forwards' }}><Shape id={id} outline /></div>
        <Shape id={id} outline />
      </div>
    );
  }

  function buildSeq(n, len) {
    const s = [];
    for (let i = 0; i < len; i++) {
      if (i >= n && Math.random() < RATE) { s.push(s[i - n]); continue; }
      let c; do { c = Math.floor(Math.random() * NSHAPES); } while (i >= n && c === s[i - n]);
      s.push(c);
    }
    return s;
  }

  function NBack({ onExit, baseline }) {
    const ROUND = baseline && baseline.trials ? baseline.trials : DEF_ROUND;
    const [ui, setUi] = useState({ phase: 'intro', n: CS.store.get('nback-n', 2), idx: 0, shape: null, showing: false, fb: null, summary: null, levelMsg: null });
    const eng = useRef(null);
    const blRef = useRef(baseline); blRef.current = baseline;
    if (!eng.current) {
      const up = (p) => setUi((s) => ({ ...s, ...p }));
      eng.current = {
        n: CS.store.get('nback-n', 2), idx: 0, seq: [], results: [], resolved: false, timers: [], lastAcc: CS.store.get('nback-acc', null), phase: 'intro',
        clear() { this.timers.forEach(clearTimeout); this.timers = []; },
        after(ms, fn) { this.timers.push(setTimeout(fn, ms)); },
        action() { if (this.phase === 'intro' || this.phase === 'round') this.start(); else if (this.phase === 'playing') this.tap(); },
        start() { this.clear(); this.seq = buildSeq(this.n, ROUND); this.idx = 0; this.results = []; this.phase = 'playing'; up({ phase: 'playing', n: this.n, summary: null, levelMsg: null }); this.trial(); },
        trial() { this.clear(); this.resolved = false; const i = this.idx; up({ idx: i, shape: this.seq[i], showing: true, fb: null }); this.after(SHOW, () => { if (!this.resolved) this.resolve(false); }); },
        tap() { if (!this.resolved) this.resolve(true); },
        resolve(tapped) {
          this.resolved = true; this.clear(); const i = this.idx;
          const truth = i >= this.n && this.seq[i] === this.seq[i - this.n];
          let correct, fb;
          if (tapped) { correct = truth; fb = truth ? 'hit' : 'wrong'; } else { correct = !truth; fb = truth ? 'wrong' : null; }
          this.results.push(correct);
          if (fb) { up({ fb, showing: true }); this.after(FB, () => this.advance()); }
          else { up({ fb: null, showing: false }); this.after(CR_BLANK, () => this.advance()); }
        },
        advance() { this.clear(); this.idx += 1; if (this.idx >= ROUND) this.finish(); else this.trial(); },
        finish() {
          this.clear();
          const acc = Math.round((this.results.filter(Boolean).length / ROUND) * 100);
          let levelMsg = null, newN = this.n;
          if (acc > 85 && this.n < 4) { newN = this.n + 1; levelMsg = `Level up · ${newN}-back`; }
          else if (acc < 60 && this.n > 1) { newN = this.n - 1; levelMsg = `Eased to ${newN}-back`; }
          const delta = this.lastAcc == null ? null : { dir: acc >= this.lastAcc ? 'up' : 'down', text: `${acc >= this.lastAcc ? '+' : ''}${acc - this.lastAcc}% vs last round` };
          const playedN = this.n; this.n = newN; this.lastAcc = acc;
          CS.store.set('nback-n', newN); CS.store.set('nback-acc', acc);
          const norm = CS.normalize('nback', { acc, n: playedN }); CS.recordResult('Working Memory', norm);
          if (blRef.current) { blRef.current.onDone(norm); return; }
          this.phase = 'round';
          up({ phase: 'round', shape: null, showing: false, fb: null, summary: { acc, n: playedN, delta }, levelMsg });
        },
      };
    }
    const e = eng.current;
    useEffect(() => () => e.clear(), []);

    const playing = ui.phase === 'playing';
    return (
      <>
        {!baseline && <CS.TopBar onBack={onExit} title="N-Back" right={playing || ui.phase === 'intro' ? <Label color={T.fg} style={{ letterSpacing: '0.16em' }}>{ui.n}-Back</Label> : null} />}
        {ui.phase === 'intro' && (
          <CS.Intro onStart={() => e.action()} footnote={`${ROUND} trials`}
            legend={<div style={{ display: 'flex', gap: 12 }}>{[0, 1, 2, 3, 4, 5].map((i) => <Shape key={i} id={i} size={26} color={T.sub} />)}</div>}>
            Tap <b style={{ fontWeight: 600 }}>Match</b> when the shape is the same as the one <b style={{ fontWeight: 600 }}>{ui.n}</b> step{ui.n === 1 ? '' : 's'} back.
          </CS.Intro>
        )}
        {ui.phase === 'round' && (
          <CS.RoundEnd value={ui.summary.acc + '%'} caption="Accuracy" sub={`${ui.summary.n}-Back · ${ROUND} trials`} delta={ui.summary.delta} levelMsg={ui.levelMsg} onContinue={() => e.action()} />
        )}
        {playing && (
          <>
            <div onClick={() => e.action()} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              {ui.fb === 'hit' && <CorrectBurst id={ui.shape} />}
              {ui.fb === 'wrong' && <WrongBurst id={ui.shape} />}
              {!ui.fb && ui.showing && ui.shape != null && <div key={ui.idx} style={{ animation: 'csPop .16s ease-out' }}><Shape id={ui.shape} /></div>}
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 38 }}><CS.Progress idx={ui.idx + 1} total={ROUND} /></div>
            <CS.WideButton label="Match" onClick={() => e.action()} icon={ui.fb === 'hit' ? 'check' : ui.fb === 'wrong' ? 'cross' : null} variant={ui.fb === 'wrong' ? 'hollow' : 'solid'} />
          </>
        )}
      </>
    );
  }

  CS.register({ id: 'nback', name: 'N-Back', domain: 'Working Memory', Icon, Component: NBack });
})();
