// cs-radar.jsx — pure-SVG six-spoke cognitive radar. No chart lib, no colour.
// Shared by the baseline completion reveal and the progress dashboard.

(function () {
  const { T, Label, DOMAINS, DOMAIN_SHORT } = CS;

  function Radar({ scores, size = 252, reveal = false, ghost = null }) {
    const c = size / 2;
    const R = c - 46;                 // leave room for labels
    const N = DOMAINS.length;
    const ang = (i) => (-90 + i * (360 / N)) * Math.PI / 180;
    const pt = (i, r) => [c + r * Math.cos(ang(i)), c + r * Math.sin(ang(i))];

    const anyData = DOMAINS.some((d) => scores[d] != null);
    const rings = [0.25, 0.5, 0.75, 1];

    const vertsFor = (src) => DOMAINS.map((d, i) => {
      const v = src[d];
      const r = v == null ? R * 0.06 : R * (Math.max(4, v) / 100);
      return pt(i, r);
    });
    const verts = vertsFor(scores);
    const polyPts = verts.map((p) => p.join(',')).join(' ');

    // baseline ghost (where each domain started), only if it differs from now
    const ghostHas = ghost && DOMAINS.some((d) => ghost[d] != null);
    const ghostDiffers = ghostHas && DOMAINS.some((d) => ghost[d] != null && scores[d] != null && ghost[d] !== scores[d]);
    const ghostPts = ghostHas ? vertsFor(ghost).map((p) => p.join(',')).join(' ') : null;

    return (
      <div style={{ display: 'flex', justifyContent: 'center', animation: reveal ? 'csReveal .7s cubic-bezier(.2,.8,.2,1) both' : 'none' }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ overflow: 'visible' }}>
          {/* concentric gridline hexagons */}
          {rings.map((lvl, ri) => (
            <polygon key={ri}
              points={DOMAINS.map((_, i) => pt(i, R * lvl).join(',')).join(' ')}
              fill="none" stroke={T.line} strokeWidth={ri === rings.length - 1 ? 1.4 : 1} />
          ))}
          {/* spokes */}
          {DOMAINS.map((_, i) => {
            const [x, y] = pt(i, R);
            return <line key={i} x1={c} y1={c} x2={x} y2={y} stroke={T.line} strokeWidth="1" />;
          })}
          {/* baseline ghost polygon (where they started) */}
          {ghostDiffers && (
            <polygon points={ghostPts} fill="none" stroke={T.faint} strokeWidth="1.5" strokeDasharray="3 3" strokeLinejoin="round" />
          )}
          {/* data polygon */}
          {anyData && (
            <polygon points={polyPts} fill="rgba(17,17,17,0.07)" stroke={T.fg} strokeWidth="2" strokeLinejoin="round" />
          )}
          {/* vertices */}
          {DOMAINS.map((d, i) => {
            const v = scores[d];
            const [x, y] = verts[i];
            if (v == null) return <circle key={i} cx={x} cy={y} r="3.5" fill={T.bg} stroke={T.faint} strokeWidth="1.6" />;
            return <circle key={i} cx={x} cy={y} r="4" fill={T.fg} />;
          })}
          {/* labels */}
          {DOMAINS.map((d, i) => {
            const [lx, ly] = pt(i, R + 22);
            const cos = Math.cos(ang(i)), sin = Math.sin(ang(i));
            const anchor = cos > 0.3 ? 'start' : cos < -0.3 ? 'end' : 'middle';
            const lines = DOMAIN_SHORT[d];
            const has = scores[d] != null;
            const col = has ? T.sub : T.faint;
            const dy = sin < -0.3 ? -6 : sin > 0.3 ? 16 : 4;
            return (
              <text key={i} x={lx} y={ly + dy} textAnchor={anchor}
                style={{ fontFamily: T.font, fontSize: 9, fontWeight: 600, letterSpacing: '0.14em', fill: col }}>
                <tspan x={lx} dy="0">{lines[0]}</tspan>
                <tspan x={lx} dy="11">{lines[1]}</tspan>
              </text>
            );
          })}
        </svg>
      </div>
    );
  }

  Object.assign(window.CS, { Radar });
})();
