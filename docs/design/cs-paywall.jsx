// cs-paywall.jsx — trial-end gate. After the 28-day free trial, a blocking
// screen asks for the one-time lifetime purchase (no subscription, no ads).

(function () {
  const { T, Label, Shape } = CS;

  function Feature({ children }) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 11 }}>
        <span style={{ width: 20, height: 20, borderRadius: '50%', background: T.fg, display: 'flex', alignItems: 'center', justifyContent: 'center', flex: '0 0 auto' }}><CS.Check c={T.bg} s={11} /></span>
        <span style={{ fontFamily: T.font, fontSize: 14.5, fontWeight: 500, color: T.fg }}>{children}</span>
      </div>
    );
  }

  function Paywall({ onUnlock }) {
    return (
      <div style={{ position: 'absolute', inset: 0, background: T.bg, zIndex: 60, display: 'flex', flexDirection: 'column', animation: 'csFade .3s ease-out' }}>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 38px' }}>
          <div style={{ display: 'flex', gap: 9, marginBottom: 28 }}>{[0, 1, 2, 3, 4, 5].map((i) => <Shape key={i} id={i} size={18} color={T.sub} />)}</div>
          <Label color={T.sub}>Free trial ended</Label>
          <div style={{ fontFamily: T.font, fontSize: 27, fontWeight: 600, letterSpacing: '-0.02em', color: T.fg, textAlign: 'center', lineHeight: 1.12, marginTop: 12 }}>Unlock CogScroll<br />for life</div>
          <div style={{ fontFamily: T.font, fontSize: 15.5, fontWeight: 500, color: T.sub, textAlign: 'center', textWrap: 'pretty', lineHeight: 1.5, marginTop: 14, maxWidth: 300 }}>Your 28 days are up. One payment, yours forever — no subscription, no ads.</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 13, marginTop: 30, alignItems: 'flex-start' }}>
            <Feature>All nine games</Feature>
            <Feature>Adaptive daily sets</Feature>
            <Feature>Lifetime progress tracking</Feature>
          </div>
        </div>
        <div style={{ padding: '0 30px 40px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
          <button onClick={onUnlock}
            style={{ height: 64, width: '100%', borderRadius: 999, background: T.fg, color: T.bg, border: 'none', fontFamily: T.font, fontSize: 13.5, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', cursor: 'pointer', WebkitTapHighlightColor: 'transparent', transition: 'transform .08s', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}
            onMouseDown={(e) => (e.currentTarget.style.transform = 'scale(0.98)')}
            onMouseUp={(e) => (e.currentTarget.style.transform = '')}
            onMouseLeave={(e) => (e.currentTarget.style.transform = '')}>
            Unlock · £4 once
          </button>
        </div>
      </div>
    );
  }

  Object.assign(window.CS, { Paywall });
})();
