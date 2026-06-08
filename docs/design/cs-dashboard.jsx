// cs-dashboard.jsx — progress dashboard (lives behind Settings).
// Six-spoke radar with a faint baseline ghost + per-domain sparkline and trend
// (improving / stable / declining, recent-vs-earlier). Personal trajectory only.

(function () {
  const { T, Label } = CS;

  // tiny sparkline; auto-scales with a minimum span so noise isn't amplified
  function Spark({ data, w = 64, h = 22 }) {
    if (!data || data.length < 2) return <div style={{ width: w, height: h }} />;
    const lo = Math.min(...data), hi = Math.max(...data);
    const mid = (lo + hi) / 2, span = Math.max(hi - lo, 20);
    const lo2 = mid - span / 2, hi2 = mid + span / 2;
    const x = (i) => (i / (data.length - 1)) * (w - 2) + 1;
    const y = (v) => (h - 2) - ((v - lo2) / (hi2 - lo2)) * (h - 4);
    const pts = data.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(' ');
    return (
      <svg width={w} height={h} style={{ display: 'block', flex: '0 0 auto' }}>
        <polyline points={pts} fill="none" stroke={T.sub} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx={x(data.length - 1)} cy={y(data[data.length - 1])} r="2.2" fill={T.fg} />
      </svg>
    );
  }

  function TrendMark({ trend }) {
    if (trend.state === 'none') {
      return <span style={{ fontFamily: T.font, fontSize: 11, fontWeight: 500, color: T.faint, letterSpacing: '0.02em' }}>Not enough data yet</span>;
    }
    const up = trend.state === 'improving', down = trend.state === 'declining';
    const word = up ? 'Improving' : down ? 'Declining' : 'Stable';
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {up && <svg width="9" height="9" viewBox="0 0 11 11" fill={T.fg}><path d="M5.5 1l4 7h-8z" /></svg>}
        {down && <svg width="9" height="9" viewBox="0 0 11 11" fill={T.fg}><path d="M5.5 10l4-7h-8z" /></svg>}
        {!up && !down && <span style={{ width: 9, height: 0, borderTop: `2px solid ${T.faint}`, display: 'inline-block' }} />}
        <Label color={up || down ? T.fg : T.sub} size={10.5}>{word}</Label>
      </div>
    );
  }

  function Dashboard({ onExit }) {
    const scores = CS.domainScores();
    const baseline = CS.baselineScores();
    const measured = Object.values(scores).filter((v) => v != null).length;

    return (
      <>
        <CS.TopBar onBack={onExit} title="Progress" />
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '14px 24px 4px' }}>
            <CS.Radar scores={scores} ghost={baseline} size={250} />
            <div style={{ display: 'flex', gap: 18, marginTop: 8 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ width: 16, height: 0, borderTop: `2px solid ${T.fg}` }} />
                <Label color={T.sub} size={9.5}>Now</Label>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ width: 16, height: 0, borderTop: `2px dashed ${T.faint}` }} />
                <Label color={T.faint} size={9.5}>Baseline</Label>
              </div>
            </div>
          </div>
          <div style={{ padding: '14px 0 0' }}>
            {CS.DOMAINS.map((d) => {
              const v = scores[d];
              const trend = CS.domainTrend(d);
              return (
                <div key={d} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 28px', borderTop: `1px solid ${T.line}` }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontFamily: T.font, fontSize: 15, fontWeight: 600, color: v == null ? T.sub : T.fg, letterSpacing: '-0.01em' }}>{d}</div>
                    <div style={{ marginTop: 9 }}><TrendMark trend={trend} /></div>
                  </div>
                  <Spark data={trend.history} />
                  <div style={{ width: 36, textAlign: 'right', fontFamily: T.font, fontSize: 19, fontWeight: 600, color: v == null ? T.faint : T.fg, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em', flex: '0 0 auto' }}>{v == null ? '—' : v}</div>
                </div>
              );
            })}
          </div>
          <div style={{ padding: '22px 28px 40px', textAlign: 'center', borderTop: `1px solid ${T.line}`, marginTop: 8 }}>
            <div style={{ fontFamily: T.font, fontSize: 10.5, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.faint, lineHeight: 1.6, textWrap: 'pretty', maxWidth: 270, margin: '0 auto' }}>{measured < 6 ? `${measured} of 6 domains measured · play the rest to complete your map` : 'Scores update as you play · weakest areas get prioritised'}</div>
          </div>
        </div>
      </>
    );
  }

  Object.assign(window.CS, { Dashboard });
})();
