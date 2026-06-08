// cs-icon-glyphs.jsx — CogScroll app-icon concepts.
// Pure B&W, flat geometry. Each glyph is drawn in a 100×100 box with generous
// icon padding, using motifs the product already owns (the six stimulus shapes,
// the "bloom" reward rings, the six-spoke radar, the scrollable session feed).

const INK = '#111111';
const PAPER = '#FFFFFF';

// ── individual glyphs (children of a 100×100 svg). `ink` = foreground color ──
const Glyphs = {
  // 1 · BLOOM — the signature "correct" reward motion, frozen.
  bloom(ink) {
    return (
      <g fill="none" stroke={ink} strokeWidth="0">
        <circle cx="50" cy="50" r="8.5" fill={ink} />
        <circle cx="50" cy="50" r="19" fill="none" stroke={ink} strokeWidth="3.4" opacity="0.92" />
        <circle cx="50" cy="50" r="30" fill="none" stroke={ink} strokeWidth="2.2" opacity="0.5" />
        <circle cx="50" cy="50" r="40" fill="none" stroke={ink} strokeWidth="1.4" opacity="0.22" />
      </g>
    );
  },

  // 2 · HEXAGON — one of the six stimuli; also the six cognitive domains.
  hexagon(ink) {
    return <path d="M50 19 L77 35 L77 65 L50 81 L23 65 L23 35 Z" fill={ink} strokeLinejoin="round" />;
  },

  // 3 · RADAR — the progress identity: a six-spoke web with a score polygon.
  radar(ink) {
    const R = 31, cx = 50, cy = 50;
    const dirs = [[0, -1], [0.866, -0.5], [0.866, 0.5], [0, 1], [-0.866, 0.5], [-0.866, -0.5]];
    const f = [0.86, 0.52, 0.92, 0.62, 0.74, 0.56];
    const web = dirs.map(([x, y]) => `${(cx + x * R).toFixed(1)} ${(cy + y * R).toFixed(1)}`).join(' L ');
    const data = dirs.map(([x, y], i) => `${(cx + x * R * f[i]).toFixed(1)} ${(cy + y * R * f[i]).toFixed(1)}`).join(' L ');
    return (
      <g>
        <path d={`M ${web} Z`} fill="none" stroke={ink} strokeWidth="1.4" opacity="0.24" strokeLinejoin="round" />
        {dirs.map(([x, y], i) => <line key={i} x1={cx} y1={cy} x2={(cx + x * R).toFixed(1)} y2={(cy + y * R).toFixed(1)} stroke={ink} strokeWidth="1.1" opacity="0.16" />)}
        <path d={`M ${data} Z`} fill={ink} opacity="0.9" strokeLinejoin="round" />
      </g>
    );
  },

  // 4 · FEED — a stack of cards you scroll through (the reframed "scroll").
  feed(ink) {
    const card = (x, y, fill, op, sw) => <rect x={x} y={y} width="40" height="40" rx="9" fill={fill} stroke={ink} strokeWidth={sw} opacity={op} />;
    return (
      <g>
        {card(38, 21, 'none', 0.32, 2.4)}
        {card(30, 30, 'none', 0.55, 2.4)}
        {card(22, 39, ink, 1, 0)}
      </g>
    );
  },

  // 5 · ALPHABET — the six stimulus shapes, the product's whole vocabulary.
  alphabet(ink) {
    const r = 7.6;
    const circle = (cx, cy) => <circle cx={cx} cy={cy} r={r} fill={ink} />;
    const square = (cx, cy) => <rect x={cx - r} y={cy - r} width={r * 2} height={r * 2} rx="1.8" fill={ink} />;
    const tri = (cx, cy) => <path d={`M${cx} ${cy - r} L${cx + r} ${cy + r * 0.8} L${cx - r} ${cy + r * 0.8} Z`} fill={ink} strokeLinejoin="round" />;
    const diamond = (cx, cy) => <path d={`M${cx} ${cy - r} L${cx + r} ${cy} L${cx} ${cy + r} L${cx - r} ${cy} Z`} fill={ink} />;
    const cross = (cx, cy) => { const a = 2.7, b = r; return <path d={`M${cx - a} ${cy - b} h${a * 2} v${b - a} h${b - a} v${a * 2} h${-(b - a)} v${b - a} h${-a * 2} v${-(b - a)} h${-(b - a)} v${-a * 2} h${b - a} z`} fill={ink} />; };
    const hex = (cx, cy) => <path d={`M${cx} ${cy - r} L${cx + r * 0.87} ${cy - r * 0.5} L${cx + r * 0.87} ${cy + r * 0.5} L${cx} ${cy + r} L${cx - r * 0.87} ${cy + r * 0.5} L${cx - r * 0.87} ${cy - r * 0.5} Z`} fill={ink} strokeLinejoin="round" />;
    const cols = [35, 65], rows = [31, 50, 69];
    return (
      <g>
        {circle(cols[0], rows[0])}{square(cols[1], rows[0])}
        {tri(cols[0], rows[1])}{diamond(cols[1], rows[1])}
        {cross(cols[0], rows[2])}{hex(cols[1], rows[2])}
      </g>
    );
  },

  // 6 · SCROLL — a column of stimuli fading at the edges: an endless, calmer feed.
  scroll(ink) {
    const r = 8.5;
    return (
      <g mask="url(#csFade)">
        <circle cx="50" cy="20" r={r} fill={ink} />
        <rect x={50 - r} y={40 - r} width={r * 2} height={r * 2} rx="2.2" fill={ink} />
        <path d={`M50 ${60 - r} L${50 + r} 60 L50 ${60 + r} L${50 - r} 60 Z`} fill={ink} />
        <path d={`M50 ${80 - r} L${50 + r} ${80 + r * 0.85} L${50 - r} ${80 + r * 0.85} Z`} fill={ink} strokeLinejoin="round" />
      </g>
    );
  },
};

// fade mask used by the scroll glyph
function ScrollDefs() {
  return (
    <defs>
      <linearGradient id="csFadeGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#fff" stopOpacity="0" />
        <stop offset="0.22" stopColor="#fff" stopOpacity="1" />
        <stop offset="0.78" stopColor="#fff" stopOpacity="1" />
        <stop offset="1" stopColor="#fff" stopOpacity="0" />
      </linearGradient>
      <mask id="csFade"><rect x="0" y="0" width="100" height="100" fill="url(#csFadeGrad)" /></mask>
    </defs>
  );
}

window.CSIcons = { Glyphs, ScrollDefs, INK, PAPER };
