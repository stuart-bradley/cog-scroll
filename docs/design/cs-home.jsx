// cs-home.jsx — top level. Leads with the adaptive "Today" set (guided session),
// with the full game catalog below. Pre-baseline, Today is locked and invites
// the baseline. Settings (incl. the progress dashboard) lives in the header.

const DOMAIN_ORDER = ['Working Memory', 'Attention & Inhibition', 'Sustained Attention', 'Mental Flexibility', 'Processing Speed', 'Spatial Reasoning'];

function TodaySet({ onPick }) {
  const { T, Label } = CS;
  const sess = CS.getTodaySession();
  const prog = CS.todayProgress();
  const allDone = prog.done >= prog.total;

  const tiles = sess.steps.map((st, i) => {
    const g = CS.games.find((x) => x.id === st.id);
    const done = sess.done[i];
    if (!g) return null;
    return (
      <div key={i} title={g.name} style={{ position: 'relative', width: 46, height: 46, borderRadius: 13, background: T.panel, display: 'flex', alignItems: 'center', justifyContent: 'center', flex: '0 0 auto', opacity: done ? 0.4 : 1 }}>
        <g.Icon />
        {st.focus && !done && <span style={{ position: 'absolute', top: 5, right: 5, width: 5, height: 5, borderRadius: '50%', background: T.fg }} />}
        {done && <span style={{ position: 'absolute', bottom: -3, right: -3, width: 18, height: 18, borderRadius: '50%', background: T.fg, border: `2px solid ${T.bg}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CS.Check c={T.bg} s={9} /></span>}
      </div>
    );
  });

  return (
    <>
      <div style={{ padding: '14px 28px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <Label color={T.sub} size={10.5} style={{ letterSpacing: '0.2em' }}>Today</Label>
        <Label color={T.faint} size={10.5}>{prog.done} / {prog.total} done</Label>
      </div>
      {allDone ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 26px 14px' }}>
          <div style={{ flex: 1, display: 'flex', gap: 8, minWidth: 0 }}>{tiles}</div>
          <Label color={T.faint} size={10}>Done</Label>
        </div>
      ) : (
        <button onClick={() => onPick('session')}
          style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '6px 26px 14px', border: 'none', background: 'transparent', cursor: 'pointer', textAlign: 'left', WebkitTapHighlightColor: 'transparent' }}
          onMouseEnter={(e) => (e.currentTarget.style.background = T.panel)}
          onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}>
          <div style={{ flex: 1, display: 'flex', gap: 8, minWidth: 0 }}>{tiles}</div>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flex: '0 0 auto' }}><path d="M6 3l5 5-5 5" /></svg>
        </button>
      )}
    </>
  );
}

function TodayLocked({ onPick }) {
  const { T, Label } = CS;
  return (
    <div style={{ margin: '8px 24px 14px', borderRadius: 20, background: T.fg, color: T.bg, padding: '24px 22px 22px', animation: 'csFade .3s ease-out' }}>
      <Label color="rgba(255,255,255,0.55)" size={10.5}>Today</Label>
      <div style={{ marginTop: 11, fontFamily: T.font, fontSize: 20, fontWeight: 600, letterSpacing: '-0.01em' }}>Your daily set</div>
      <div style={{ marginTop: 7, fontFamily: T.font, fontSize: 14, fontWeight: 500, color: 'rgba(255,255,255,0.72)', lineHeight: 1.45, maxWidth: 256 }}>A short, adaptive set that targets your weaker domains. Unlocks after a five-minute baseline.</div>
      <button onClick={() => onPick('baseline')} style={{ marginTop: 18, height: 46, padding: '0 24px', borderRadius: 999, background: T.bg, color: T.fg, border: 'none', fontFamily: T.font, fontSize: 12, fontWeight: 600, letterSpacing: '0.2em', textTransform: 'uppercase', cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>Find your baseline</button>
    </div>
  );
}

function Home({ onPick }) {
  const { T, Label } = CS;
  const onboarded = CS.store.get('onboarded', false);

  const groups = {};
  CS.games.forEach((g) => { (groups[g.domain] = groups[g.domain] || []).push(g); });
  const order = DOMAIN_ORDER.filter((d) => groups[d]);
  Object.keys(groups).forEach((d) => { if (!order.includes(d)) order.push(d); });

  return (
    <>
      <div style={{ padding: '40px 28px 18px', flex: '0 0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontFamily: T.font, fontSize: 30, fontWeight: 600, letterSpacing: '-0.02em', color: T.fg, lineHeight: 1 }}>CogScroll</div>
          <div style={{ marginTop: 12 }}><Label color={T.sub}>{CS.games.length} games · {order.length} domains</Label></div>
        </div>
        <button onClick={() => onPick('settings')} aria-label="Settings" style={{ border: 'none', background: 'transparent', padding: 4, margin: '-2px -4px 0 0', cursor: 'pointer', display: 'flex', WebkitTapHighlightColor: 'transparent' }}>
          <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke={T.fg} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 7h9M16 7h3" /><circle cx="14" cy="7" r="2.1" fill={T.bg} />
            <path d="M3 15h3M10 15h9" /><circle cx="8" cy="15" r="2.1" fill={T.bg} />
          </svg>
        </button>
      </div>
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {onboarded ? <TodaySet onPick={onPick} /> : <TodayLocked onPick={onPick} />}

        {order.map((domain) => (
          <div key={domain}>
            <div style={{ padding: '18px 28px 8px', position: 'sticky', top: 0, background: T.bg, borderTop: `1px solid ${T.line}` }}>
              <Label color={T.sub} size={10.5} style={{ letterSpacing: '0.2em' }}>{domain}</Label>
            </div>
            {groups[domain].map((g) => (
              <button key={g.id} onClick={() => onPick(g.id)}
                style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 16, padding: '13px 26px', border: 'none', background: 'transparent', cursor: 'pointer', textAlign: 'left', WebkitTapHighlightColor: 'transparent' }}
                onMouseEnter={(e) => (e.currentTarget.style.background = T.panel)}
                onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}>
                <div style={{ width: 44, height: 44, borderRadius: 12, background: T.panel, display: 'flex', alignItems: 'center', justifyContent: 'center', flex: '0 0 auto' }}>{g.Icon ? <g.Icon /> : null}</div>
                <div style={{ flex: 1, minWidth: 0, fontFamily: T.font, fontSize: 17, fontWeight: 600, color: T.fg, letterSpacing: '-0.01em' }}>{g.name}</div>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flex: '0 0 auto' }}><path d="M6 3l5 5-5 5" /></svg>
              </button>
            ))}
          </div>
        ))}
        <div style={{ padding: '24px 28px 40px', textAlign: 'center', borderTop: `1px solid ${T.line}`, marginTop: 8 }}>
          <Label color={T.faint} size={10.5}>Local-first · no account</Label>
        </div>
      </div>
    </>
  );
}

window.CS.Home = Home;
