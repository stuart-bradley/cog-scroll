// cs-core.jsx — CogScroll shared core. Pure black & white, Space Grotesk,
// flat geometry, motion-led feedback (bloom on correct, shake/ghost on wrong).
// Exposes window.CS: tokens, atoms, feedback, chrome, round-end, registry.

const { useState, useRef, useEffect, useCallback } = React;

const T = { bg: '#FFFFFF', fg: '#111111', sub: 'rgba(17,17,17,0.42)', faint: 'rgba(17,17,17,0.2)', line: 'rgba(17,17,17,0.14)', panel: '#F4F4F4', font: "'Space Grotesk', sans-serif" };

// ── atoms ───────────────────────────────────────────────────────────────────
function Label({ children, color, size = 12, style = {} }) {
  return <span style={{ fontFamily: T.font, fontSize: size, fontWeight: 600, letterSpacing: '0.22em', textTransform: 'uppercase', whiteSpace: 'nowrap', color: color || T.sub, lineHeight: 1, ...style }}>{children}</span>;
}
const Check = ({ c = '#fff', s = 16 }) => <svg width={s} height={s} viewBox="0 0 16 16" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M3 8.5l3.2 3.2L13 4.5" /></svg>;
const Cross = ({ c = '#111', s = 15 }) => <svg width={s} height={s} viewBox="0 0 15 15" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round"><path d="M3.5 3.5l8 8M11.5 3.5l-8 8" /></svg>;

// ── the six flat stimulus shapes (filled or outlined) ───────────────────────
function Shape({ id, size = 158, color = T.fg, outline = false }) {
  const fill = outline ? 'none' : color;
  const stroke = outline ? color : 'none';
  const c = { fill, stroke, strokeWidth: outline ? 6 : 0, strokeLinejoin: 'round' };
  const p = { width: size, height: size, display: 'block', overflow: 'visible' };
  switch (id) {
    case 0: return <svg viewBox="0 0 100 100" style={p}><circle cx="50" cy="50" r="47" {...c} /></svg>;
    case 1: return <svg viewBox="0 0 100 100" style={p}><rect x="6" y="6" width="88" height="88" rx="7" {...c} /></svg>;
    case 2: return <svg viewBox="0 0 100 100" style={p}><path d="M50 8 L92 88 L8 88 Z" {...c} /></svg>;
    case 3: return <svg viewBox="0 0 100 100" style={p}><path d="M50 5 L95 50 L50 95 L5 50 Z" {...c} /></svg>;
    case 4: return <svg viewBox="0 0 100 100" style={p}><path d="M37 7 h26 v30 h30 v26 h-30 v30 h-26 v-30 h-30 v-26 h30 z" {...c} /></svg>;
    case 5: return <svg viewBox="0 0 100 100" style={p}><path d="M50 6 L88 28 V72 L50 94 L12 72 V28 Z" {...c} /></svg>;
    default: return null;
  }
}
const SHAPE_NAMES = ['Circle', 'Square', 'Triangle', 'Diamond', 'Cross', 'Hexagon'];

// ── feedback: expanding confirm bloom (correct), centered on its parent ─────
function Bloom({ size = 212, radius = '50%' }) {
  const ring = (w, anim) => ({ position: 'absolute', left: -size / 2, top: -size / 2, width: size, height: size, borderRadius: radius, border: `${w}px solid ${T.fg}`, animation: anim, pointerEvents: 'none' });
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
      <div style={{ position: 'relative', width: 0, height: 0 }}>
        <div style={ring(7, 'csRing .5s cubic-bezier(.2,.8,.2,1) forwards')} />
        <div style={ring(2, 'csRing2 .66s ease-out forwards')} />
      </div>
    </div>
  );
}

// ── feedback: double-pulse (square-conforming correct), centered on parent ──
function Pulse({ size = 170, radius = 20 }) {
  const ring = (delay) => ({ position: 'absolute', left: -size / 2, top: -size / 2, width: size, height: size, borderRadius: radius, border: `5px solid ${T.fg}`, animation: `csPulse .62s ease-out ${delay} forwards`, pointerEvents: 'none' });
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
      <div style={{ position: 'relative', width: 0, height: 0 }}>
        <div style={ring('0s')} />
        <div style={ring('.16s')} />
      </div>
    </div>
  );
}

// ── chrome ──────────────────────────────────────────────────────────────────
function TopBar({ onBack, title, right }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '30px 24px 0', flex: '0 0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        {onBack && (
          <button onClick={onBack} aria-label="Back" style={{ border: 'none', background: 'transparent', padding: 4, margin: -4, cursor: 'pointer', display: 'flex', WebkitTapHighlightColor: 'transparent' }}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke={T.fg} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 4l-6 6 6 6" /></svg>
          </button>
        )}
        <Label color={T.sub}>{title}</Label>
      </div>
      <div>{right}</div>
    </div>
  );
}

const pillBase = { height: 64, width: '100%', borderRadius: 999, padding: '0 28px', fontFamily: T.font, fontSize: 13.5, fontWeight: 600, letterSpacing: '0.22em', textTransform: 'uppercase', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, cursor: 'pointer', WebkitTapHighlightColor: 'transparent', transition: 'transform .08s' };

function WideButton({ label, onClick, variant = 'solid', icon, disabled }) {
  const hollow = variant === 'hollow';
  const bg = disabled ? T.panel : hollow ? T.bg : T.fg;
  const fg = disabled ? T.faint : hollow ? T.fg : T.bg;
  return (
    <div style={{ padding: '0 30px 46px', flex: '0 0 auto' }}>
      <button onClick={disabled ? undefined : onClick} disabled={disabled}
        style={{ ...pillBase, background: bg, color: fg, border: hollow ? `1.6px solid ${T.fg}` : 'none', cursor: disabled ? 'default' : 'pointer', opacity: 1 }}
        onMouseDown={(e) => !disabled && (e.currentTarget.style.transform = 'scale(0.98)')}
        onMouseUp={(e) => (e.currentTarget.style.transform = '')}
        onMouseLeave={(e) => (e.currentTarget.style.transform = '')}>
        {icon === 'check' && <Check c={fg} />}{icon === 'cross' && <Cross c={fg} />}{label}
      </button>
    </div>
  );
}

function Progress({ idx, total }) {
  const pad = (x) => String(x).padStart(2, '0');
  const pct = (idx / total) * 100;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
      <span style={{ fontFamily: T.font, fontSize: 14, fontWeight: 500, color: T.sub, letterSpacing: '0.14em', fontVariantNumeric: 'tabular-nums' }}>{pad(idx)} <span style={{ opacity: 0.55 }}>/ {total}</span></span>
      <div style={{ width: 188, height: 2, background: T.line, borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ width: pct + '%', height: '100%', background: T.fg, borderRadius: 2, transition: 'width .2s ease' }} />
      </div>
    </div>
  );
}

// ── instructions / start screen (shared) ────────────────────────────────────
function Intro({ children, footnote, legend, onStart, startLabel = 'Begin' }) {
  return (
    <>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 44px', gap: 30, animation: 'csFade .3s ease-out' }}>
        {legend}
        <div style={{ fontFamily: T.font, fontSize: 21, fontWeight: 500, lineHeight: 1.45, color: T.fg, textAlign: 'center', textWrap: 'pretty' }}>{children}</div>
        {footnote && <Label color={T.sub}>{footnote}</Label>}
      </div>
      <WideButton label={startLabel} onClick={onStart} />
    </>
  );
}

// ── round-complete (generic; metric varies per game) ────────────────────────
function RoundEnd({ value, caption, sub, delta, levelMsg, onContinue, continueLabel = 'Continue' }) {
  return (
    <>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, animation: 'csFade .35s ease-out' }}>
        <div style={{ fontFamily: T.font, fontSize: 92, fontWeight: 600, lineHeight: 0.9, letterSpacing: '-0.03em', color: T.fg, fontVariantNumeric: 'tabular-nums' }}>{value}</div>
        <Label>{caption}</Label>
        {sub && <div style={{ marginTop: 12, fontFamily: T.font, fontSize: 15, fontWeight: 500, color: T.fg }}>{sub}</div>}
        {delta && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: T.fg }}>
            {delta.dir === 'up' && <svg width="11" height="11" viewBox="0 0 11 11" fill="currentColor"><path d="M5.5 1l4 7h-8z" /></svg>}
            {delta.dir === 'down' && <svg width="11" height="11" viewBox="0 0 11 11" fill="currentColor"><path d="M5.5 10l4-7h-8z" /></svg>}
            <span style={{ fontFamily: T.font, fontSize: 13, fontWeight: 500 }}>{delta.text}</span>
          </div>
        )}
        {levelMsg && <div style={{ marginTop: 14 }}><Label color={T.fg} size={12} style={{ letterSpacing: '0.2em' }}>{levelMsg}</Label></div>}
      </div>
      <WideButton label={continueLabel} onClick={onContinue} />
    </>
  );
}

// ── persistence + staircase helpers ─────────────────────────────────────────
const store = {
  get(k, d) { try { const v = localStorage.getItem('cogscroll:' + k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } },
  set(k, v) { try { localStorage.setItem('cogscroll:' + k, JSON.stringify(v)); } catch (e) {} },
};

// ── response-window countdown (depleting line) for fast timed tasks ─────────
function Countdown({ ms, k }) {
  return (
    <div style={{ width: 210, height: 3, background: T.line, borderRadius: 2, overflow: 'hidden' }}>
      <div key={k} style={{ height: '100%', width: '100%', background: T.fg, borderRadius: 2, transformOrigin: 'left center', animation: `csDeplete ${ms}ms linear forwards` }} />
    </div>
  );
}

// ── game registry ───────────────────────────────────────────────────────────
const games = [];
function register(g) { games.push(g); }

window.CS = { T, Label, Check, Cross, Shape, SHAPE_NAMES, Bloom, Pulse, Countdown, TopBar, WideButton, Progress, Intro, RoundEnd, store, games, register, useState, useRef, useEffect, useCallback };
