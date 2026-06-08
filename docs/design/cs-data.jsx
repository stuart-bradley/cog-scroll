// cs-data.jsx — shared cognitive-domain data layer.
// Seeds the dashboard + the adaptive session picker from a single source.
// Each game's finish() calls CS.recordResult(domain, normalizedScore 0–100).
// Normalization maps each raw metric onto the spec's good/avg/poor bands.
// No colour, no backend — pure local-first analytics.

(function () {
  const { store } = CS;

  // The six tracked domains, in radar order (clockwise from top).
  const DOMAINS = [
    'Working Memory',
    'Processing Speed',
    'Attention & Inhibition',
    'Mental Flexibility',
    'Spatial Reasoning',
    'Sustained Attention',
  ];

  // Short two-line labels for the radar (long names don't fit around a hexagon).
  const DOMAIN_SHORT = {
    'Working Memory': ['WORKING', 'MEMORY'],
    'Processing Speed': ['PROCESS', 'SPEED'],
    'Attention & Inhibition': ['ATTENTION', '& INHIB'],
    'Mental Flexibility': ['MENTAL', 'FLEX'],
    'Spatial Reasoning': ['SPATIAL', 'REASON'],
    'Sustained Attention': ['SUSTAIN', 'ATTN'],
  };

  // Performance keys that constitute "analytics" — cleared on a baseline redo.
  const PERF_KEYS = [
    'domains', 'onboarded',
    'nback-n', 'nback-acc', 'digit-span', 'corsi-span', 'stroop-acc',
    'flanker-acc', 'gng-acc', 'switch-acc', 'trail-time', 'rt-avg',
  ];

  // ── normalization (raw metric → 0–100 vs population norms) ─────────────────
  const clamp = (x) => Math.max(0, Math.min(100, x));
  function piece(x, pts) {
    // pts: [[rawX, score], …] with rawX ascending. Piecewise-linear.
    if (x <= pts[0][0]) return pts[0][1];
    for (let i = 1; i < pts.length; i++) {
      if (x <= pts[i][0]) {
        const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
        return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
      }
    }
    return pts[pts.length - 1][1];
  }

  // key → normalized score. `raw` is a number except n-back ({acc, n}).
  function normalize(key, raw) {
    switch (key) {
      // Working Memory — n-back accuracy, lifted by the level reached.
      case 'nback': {
        const eff = raw.acc + (raw.n - 2) * 15;
        return Math.round(clamp(piece(eff, [[40, 15], [60, 35], [75, 58], [85, 78], [100, 100]])));
      }
      case 'digit-span': return Math.round(clamp(piece(raw, [[3, 15], [4, 30], [6, 55], [7, 68], [8, 82], [10, 100]])));
      case 'corsi-span': return Math.round(clamp(piece(raw, [[2, 10], [3, 25], [5, 55], [6, 68], [7, 82], [9, 100]])));
      // lower-is-better metrics (ms / seconds) → x ascending, score descending.
      case 'rt-avg': return Math.round(clamp(piece(raw, [[180, 100], [220, 82], [260, 62], [300, 45], [350, 28], [450, 8]])));
      case 'trail-time': return Math.round(clamp(piece(raw, [[12, 100], [20, 82], [30, 58], [40, 42], [60, 22], [90, 5]])));
      // accuracy-based attention / flexibility tasks.
      case 'flanker-acc': return Math.round(clamp(piece(raw, [[60, 10], [85, 35], [90, 58], [95, 80], [100, 100]])));
      case 'gng-acc': return Math.round(clamp(piece(raw, [[60, 10], [85, 38], [92, 62], [97, 84], [100, 100]])));
      case 'stroop-acc': return Math.round(clamp(piece(raw, [[50, 12], [70, 40], [82, 60], [90, 78], [100, 100]])));
      case 'switch-acc': return Math.round(clamp(piece(raw, [[50, 12], [70, 40], [82, 60], [90, 78], [100, 100]])));
      default: return Math.round(clamp(raw));
    }
  }

  // ── domain store ───────────────────────────────────────────────────────────
  // { [domain]: { score: 0–100, history: [{ t, score }] } }
  function getDomains() { return store.get('domains', {}); }

  // Rolling score weighted toward recent performance (EMA, α favouring latest).
  function recordResult(domain, score) {
    if (!DOMAINS.includes(domain)) return;
    const d = getDomains();
    const rec = d[domain] || { score: null, history: [] };
    rec.history = (rec.history || []).concat([{ t: Date.now(), score }]);
    if (rec.history.length > 60) rec.history = rec.history.slice(-60);
    rec.score = rec.score == null ? score : Math.round(rec.score * 0.6 + score * 0.4);
    d[domain] = rec;
    store.set('domains', d);
  }

  // { domain: score|null } for every domain (null = not yet measured).
  function domainScores() {
    const d = getDomains();
    const out = {};
    DOMAINS.forEach((k) => { out[k] = d[k] && d[k].score != null ? d[k].score : null; });
    return out;
  }

  function hasData() { return Object.values(domainScores()).some((v) => v != null); }

  // ── trends (recent-vs-earlier) + baseline ghost ─────────────────────────────
  function domainHistory(domain) {
    const d = getDomains();
    return d[domain] && d[domain].history ? d[domain].history.map((h) => h.score) : [];
  }

  // first measured score per domain (the baseline polygon on the radar)
  function baselineScores() {
    const d = getDomains();
    const out = {};
    DOMAINS.forEach((k) => { const h = d[k] && d[k].history; out[k] = h && h.length ? h[0].score : null; });
    return out;
  }

  // improving / stable / declining, by averaging the last ~3 vs the ones before.
  // Needs >= 3 results; 'up' already means better (normalization inverts time/ms).
  const STABLE = 4;
  function domainTrend(domain) {
    const h = domainHistory(domain);
    const n = h.length;
    if (n < 3) return { state: 'none', delta: 0, n, history: h };
    const k = Math.min(3, Math.floor(n / 2));
    const recent = h.slice(n - k), earlier = h.slice(0, n - k);
    const avg = (a) => a.reduce((x, y) => x + y, 0) / a.length;
    const delta = Math.round(avg(recent) - avg(earlier));
    const state = delta >= STABLE ? 'improving' : delta <= -STABLE ? 'declining' : 'stable';
    return { state, delta, n, history: h };
  }

  // ── export / import / clear ─────────────────────────────────────────────────
  function snapshot() {
    const out = {};
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      if (k && k.indexOf('cogscroll:') === 0) {
        try { out[k.slice(10)] = JSON.parse(localStorage.getItem(k)); } catch (e) {}
      }
    }
    return { app: 'CogScroll', version: 1, exportedAt: new Date().toISOString(), data: out };
  }

  function exportData() {
    const blob = new Blob([JSON.stringify(snapshot(), null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'cogscroll-' + new Date().toISOString().slice(0, 10) + '.json';
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  // Returns a count of imported keys, or throws on a malformed payload.
  function importData(text) {
    const parsed = JSON.parse(text);
    const data = parsed && parsed.data ? parsed.data : parsed;
    if (!data || typeof data !== 'object') throw new Error('Unrecognised file');
    let n = 0;
    Object.keys(data).forEach((k) => { store.set(k, data[k]); n++; });
    return n;
  }

  function clearAnalytics() {
    PERF_KEYS.forEach((k) => { try { localStorage.removeItem('cogscroll:' + k); } catch (e) {} });
  }

  // ── trial / one-time membership ──────────────────────────────────────
  const TRIAL_DAYS = 28;
  function initTrial() { if (store.get('trialStart', null) == null) store.set('trialStart', Date.now()); }
  function trialInfo() {
    const start = store.get('trialStart', Date.now());
    const elapsed = Math.floor((Date.now() - start) / 86400000);
    const purchased = store.get('purchased', false);
    return { start, elapsed, daysLeft: Math.max(0, TRIAL_DAYS - elapsed), purchased, expired: elapsed >= TRIAL_DAYS && !purchased };
  }
  function purchase() { store.set('purchased', true); }
  initTrial();

  Object.assign(window.CS, {
    DOMAINS, DOMAIN_SHORT, normalize, recordResult, getDomains, domainScores, hasData,
    domainHistory, baselineScores, domainTrend,
    exportData, importData, clearAnalytics,
    TRIAL_DAYS, trialInfo, purchase,
  });
})();
