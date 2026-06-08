// cs-icon-app.jsx — presents the CogScroll icon concepts on the design canvas.

const { useState: useStateI } = React;
const { Glyphs, ScrollDefs, INK, PAPER } = window.CSIcons;
const FONT = "'Space Grotesk', sans-serif";

// ── one squircle tile at an arbitrary pixel size ────────────────────────────
function Tile({ glyph, dark, size }) {
  const ink = dark ? PAPER : INK;
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.225,
      background: dark ? INK : PAPER,
      boxShadow: dark ? '0 1px 2px rgba(0,0,0,0.18)' : 'inset 0 0 0 1px rgba(17,17,17,0.10), 0 1px 2px rgba(0,0,0,0.06)',
      display: 'flex', flexShrink: 0, overflow: 'hidden',
    }}>
      <svg viewBox="0 0 100 100" width="100%" height="100%" style={{ display: 'block' }}>
        <ScrollDefs />
        {Glyphs[glyph](ink)}
      </svg>
    </div>
  );
}

const microLabel = { fontFamily: FONT, fontSize: 11, fontWeight: 600, letterSpacing: '0.22em', textTransform: 'uppercase', color: 'rgba(17,17,17,0.42)' };

// ── a concept: hero tile (chosen theme) + the other theme + size ramp + note ─
function Concept({ glyph, dark, name, note }) {
  return (
    <div style={{ width: '100%', height: '100%', background: '#FBFBFB', display: 'flex', flexDirection: 'column', padding: 28, gap: 22 }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 20 }}>
        <Tile glyph={glyph} dark={dark} size={132} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Tile glyph={glyph} dark={!dark} size={60} />
          <span style={{ ...microLabel, fontSize: 9.5, letterSpacing: '0.16em' }}>alt</span>
        </div>
      </div>

      {/* size legibility ramp, in the hero theme */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 16 }}>
        {[60, 40, 29, 20].map((s) => <Tile key={s} glyph={glyph} dark={dark} size={s} />)}
      </div>

      <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <span style={microLabel}>{name}</span>
        <p style={{ margin: 0, fontFamily: FONT, fontSize: 14.5, fontWeight: 400, lineHeight: 1.5, color: INK, textWrap: 'pretty' }}>{note}</p>
      </div>
    </div>
  );
}

const CONCEPTS = [
  { id: 'bloom', glyph: 'bloom', dark: true, name: '01 · Bloom', note: 'The reward rings that pulse out on every correct answer — the one motion users feel most. Owns a moment no competitor has.' },
  { id: 'hexagon', glyph: 'hexagon', dark: false, name: '02 · Hex', note: 'A single stimulus shape that doubles as the six cognitive domains. The simplest, most scalable mark — reads at any size.' },
  { id: 'radar', glyph: 'radar', dark: false, name: '03 · Radar', note: 'The six-spoke progress web that is the heart of the dashboard. Says “measured growth” at a glance.' },
  { id: 'feed', glyph: 'feed', dark: false, name: '04 · Feed', note: 'A stack of cards you move through — the “scroll” in CogScroll, reframed from doomscroll into deliberate training.' },
  { id: 'alphabet', glyph: 'alphabet', dark: false, name: '05 · Alphabet', note: 'All six stimulus shapes — the product’s entire visual vocabulary in one tile. Playful, unmistakably this app.' },
  { id: 'scroll', glyph: 'scroll', dark: true, name: '06 · Scroll', note: 'A quiet, endless column of stimuli fading at the edges — the calm anti-feed. Most literal to the name.' },
];

function App() {
  return (
    <DesignCanvas>
      <DCSection id="icons" title="CogScroll — App Icon" subtitle="Six directions, all from the existing system · pure mono, flat geometry · open any tile fullscreen to inspect">
        {CONCEPTS.map((c) => (
          <DCArtboard key={c.id} id={c.id} label={c.name.replace(/^\d+ · /, '')} width={336} height={384}>
            <Concept {...c} />
          </DCArtboard>
        ))}
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
