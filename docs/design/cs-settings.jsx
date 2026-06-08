// cs-settings.jsx — redo baseline (wipes analytics, confirmed) + export/import JSON.

(function () {
  const { useState, useRef, T, Label } = CS;

  const Chevron = () => <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 3l5 5-5 5" /></svg>;

  function Row({ label, sub, onClick, right }) {
    return (
      <button onClick={onClick}
        style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 14, padding: '16px 28px', border: 'none', background: 'transparent', cursor: 'pointer', textAlign: 'left', borderTop: `1px solid ${T.line}`, WebkitTapHighlightColor: 'transparent' }}
        onMouseEnter={(e) => (e.currentTarget.style.background = T.panel)}
        onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: T.font, fontSize: 16, fontWeight: 600, color: T.fg, letterSpacing: '-0.01em' }}>{label}</div>
          {sub && <div style={{ marginTop: 4, fontFamily: T.font, fontSize: 12.5, fontWeight: 500, color: T.sub, lineHeight: 1.4 }}>{sub}</div>}
        </div>
        {right === undefined ? <Chevron /> : right}
      </button>
    );
  }

  function Sec({ children }) {
    return <div style={{ padding: '26px 28px 6px' }}><Label color={T.sub} size={10.5} style={{ letterSpacing: '0.2em' }}>{children}</Label></div>;
  }

  function Toggle({ on, onChange }) {
    return (
      <button onClick={() => onChange(!on)} aria-pressed={on}
        style={{ width: 48, height: 28, borderRadius: 999, border: 'none', background: on ? T.fg : '#E2E2E2', position: 'relative', cursor: 'pointer', padding: 0, flex: '0 0 auto', transition: 'background .15s', WebkitTapHighlightColor: 'transparent' }}>
        <span style={{ position: 'absolute', top: 4, left: on ? 25 : 3, width: 20, height: 20, borderRadius: '50%', background: '#fff', boxShadow: '0 1px 2px rgba(0,0,0,0.25)', transition: 'left .15s' }} />
      </button>
    );
  }

  const spinBtn = { border: 'none', background: 'transparent', cursor: 'pointer', padding: 6, display: 'flex', WebkitTapHighlightColor: 'transparent' };
  function Spin({ value, onUp, onDown }) {
    const chev = (d) => <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: d === 'up' ? 'rotate(-90deg)' : 'rotate(90deg)' }}><path d="M6 3l5 5-5 5" /></svg>;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
        <button onClick={onUp} style={spinBtn} aria-label="Increase">{chev('up')}</button>
        <div style={{ fontFamily: T.font, fontSize: 36, fontWeight: 600, color: T.fg, fontVariantNumeric: 'tabular-nums', lineHeight: 1, minWidth: 50, textAlign: 'center' }}>{value}</div>
        <button onClick={onDown} style={spinBtn} aria-label="Decrease">{chev('down')}</button>
      </div>
    );
  }
  function TimePicker({ value, onChange }) {
    const h = value.h, m = value.m, h12 = (h % 12) || 12, ampm = h < 12 ? 'AM' : 'PM';
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '4px 0 2px' }}>
        <Spin value={String(h12)} onUp={() => onChange({ h: (h + 1) % 24, m })} onDown={() => onChange({ h: (h + 23) % 24, m })} />
        <div style={{ fontFamily: T.font, fontSize: 32, fontWeight: 600, color: T.faint, marginTop: -2 }}>:</div>
        <Spin value={String(m).padStart(2, '0')} onUp={() => onChange({ h, m: (m + 15) % 60 })} onDown={() => onChange({ h, m: (m + 45) % 60 })} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginLeft: 10 }}>
          {['AM', 'PM'].map((p) => (
            <button key={p} onClick={() => onChange({ h: p === 'AM' ? (h % 12) : (h % 12) + 12, m })}
              style={{ padding: '6px 12px', borderRadius: 10, border: `1.4px solid ${ampm === p ? T.fg : T.line}`, background: ampm === p ? T.fg : T.bg, color: ampm === p ? T.bg : T.sub, fontFamily: T.font, fontSize: 11, fontWeight: 600, letterSpacing: '0.14em', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>{p}</button>
          ))}
        </div>
      </div>
    );
  }

  function Settings({ onExit, go }) {
    const onboarded = CS.store.get('onboarded', false);
    const hasData = CS.hasData();
    const trial = CS.trialInfo();
    const [confirm, setConfirm] = useState(false);
    const [msg, setMsg] = useState(null);
    const [notify, setNotify] = useState(CS.store.get('notify', false));
    const [time, setTime] = useState(CS.store.get('notifyTime', { h: 9, m: 0 }));
    const [paid, setPaid] = useState(trial.purchased);
    const fileRef = useRef(null);

    const toggleNotify = (v) => { setNotify(v); CS.store.set('notify', v); if (v) CS.store.set('notifyTime', time); };
    const setTimeStore = (t) => { setTime(t); CS.store.set('notifyTime', t); };
    const h12 = (time.h % 12) || 12, ampm = time.h < 12 ? 'AM' : 'PM';

    const onImport = (e) => {
      const f = e.target.files && e.target.files[0];
      if (!f) return;
      const r = new FileReader();
      r.onload = () => {
        try { const n = CS.importData(String(r.result)); setMsg(`Imported ${n} item${n === 1 ? '' : 's'}. Reopen Progress to see it.`); }
        catch (err) { setMsg('That file could not be read.'); }
      };
      r.readAsText(f);
      e.target.value = '';
    };

    return (
      <>
        <CS.TopBar onBack={onExit} title="Settings" />
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {(onboarded || hasData) && (<>
            <Sec>Progress</Sec>
            <Row label="View progress" sub="Radar + per-domain trends across your six domains" onClick={() => go('dashboard')} />
          </>)}

          <Sec>Reminders</Sec>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px 28px', borderTop: `1px solid ${T.line}` }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: T.font, fontSize: 16, fontWeight: 600, color: T.fg, letterSpacing: '-0.01em' }}>Daily reminder</div>
              <div style={{ marginTop: 4, fontFamily: T.font, fontSize: 12.5, fontWeight: 500, color: T.sub, lineHeight: 1.4 }}>{notify ? `A nudge to play today’s set at ${h12}:${String(time.m).padStart(2, '0')} ${ampm}` : 'Off'}</div>
            </div>
            <Toggle on={notify} onChange={toggleNotify} />
          </div>
          {notify && (
            <div style={{ padding: '10px 28px 18px', animation: 'csFade .2s ease-out' }}>
              <TimePicker value={time} onChange={setTimeStore} />
            </div>
          )}

          <Sec>Membership</Sec>
          {paid ? (
            <Row label="Lifetime access" sub="Unlocked · no subscription, no ads" onClick={() => {}} right={<span style={{ width: 22, height: 22, borderRadius: '50%', background: T.fg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CS.Check c={T.bg} s={12} /></span>} />
          ) : (
            <Row label={`Free trial · ${trial.daysLeft} day${trial.daysLeft === 1 ? '' : 's'} left`} sub="One payment unlocks CogScroll for life" onClick={() => { CS.purchase(); setPaid(true); }}
              right={<span style={{ padding: '7px 14px', borderRadius: 999, background: T.fg, color: T.bg, fontFamily: T.font, fontSize: 10.5, fontWeight: 600, letterSpacing: '0.16em', textTransform: 'uppercase' }}>Unlock</span>} />
          )}

          <Sec>Assessment</Sec>
          {!onboarded && <Row label="Start baseline" sub="Map your six domains · about 5 minutes" onClick={() => go('baseline')} />}
          {onboarded && !confirm && <Row label="Redo baseline" sub="Re-measure from scratch" onClick={() => setConfirm(true)} />}
          {onboarded && confirm && (
            <div style={{ borderTop: `1px solid ${T.line}`, padding: '20px 28px 22px', background: T.panel, animation: 'csFade .2s ease-out' }}>
              <div style={{ fontFamily: T.font, fontSize: 15.5, fontWeight: 600, color: T.fg }}>Erase all progress?</div>
              <div style={{ marginTop: 8, fontFamily: T.font, fontSize: 13.5, fontWeight: 500, color: T.sub, lineHeight: 1.5, textWrap: 'pretty' }}>
                Redoing your baseline clears every domain score and history on this device. This can&rsquo;t be undone. Export first if you want a copy.
              </div>
              <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
                <button onClick={() => setConfirm(false)}
                  style={{ flex: 1, height: 50, borderRadius: 999, border: `1.6px solid ${T.fg}`, background: T.bg, color: T.fg, fontFamily: T.font, fontSize: 12.5, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>Cancel</button>
                <button onClick={() => { CS.clearAnalytics(); setConfirm(false); go('baseline'); }}
                  style={{ flex: 1, height: 50, borderRadius: 999, border: 'none', background: T.fg, color: T.bg, fontFamily: T.font, fontSize: 12.5, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>Erase &amp; restart</button>
              </div>
            </div>
          )}

          <Sec>Backup</Sec>
          <Row label="Export progress" sub="Download all analytics as a JSON file" onClick={() => CS.exportData()} />
          <Row label="Import progress" sub="Restore from an exported JSON file" onClick={() => fileRef.current && fileRef.current.click()} />
          <input ref={fileRef} type="file" accept="application/json,.json" onChange={onImport} style={{ display: 'none' }} />
          {msg && <div style={{ padding: '14px 28px 0' }}><Label color={T.fg} size={11} style={{ letterSpacing: '0.12em', textTransform: 'none', fontWeight: 500 }}>{msg}</Label></div>}

          <div style={{ padding: '30px 28px 40px', textAlign: 'center', borderTop: `1px solid ${T.line}`, marginTop: 26 }}>
            <Label color={T.faint} size={10.5}>Local-first · no account · on-device only</Label>
          </div>
        </div>
      </>
    );
  }

  Object.assign(window.CS, { Settings });
})();
