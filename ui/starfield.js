// Star Tournaments · interactive constellation starfield.
// Three depth layers parallax against the pointer; constellations drift with
// the deepest layer. Honors prefers-reduced-motion (renders one static frame).

const GOLD = '#e7b84e';
const WHITE = '#e9ecf2';
const LINE = '#39415c';

function mulberry(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function startStarfield(canvas) {
  const ctx = canvas.getContext('2d');
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const rand = mulberry(370);

  // depth: 0 = far (moves least), 2 = near
  const stars = [];
  for (let i = 0; i < 150; i++) {
    const depth = i < 80 ? 0 : i < 125 ? 1 : 2;
    stars.push({
      x: rand(), y: rand(), depth,
      r: 0.5 + rand() * (0.7 + depth * 0.45),
      base: 0.15 + rand() * (0.35 + depth * 0.15),
      tw: 0.5 + rand() * 1.2,       // twinkle speed
      ph: rand() * Math.PI * 2,     // twinkle phase
      gold: rand() < 0.05,
    });
  }

  // constellations: chains of indices into the far layer
  const far = stars.filter((s) => s.depth === 0);
  const constellations = [];
  for (let c = 0; c < 3; c++) {
    const chain = [];
    let idx = Math.floor(rand() * far.length);
    for (let k = 0; k < 5; k++) {
      chain.push(far[idx]);
      // walk to a nearby-ish star for a plausible constellation shape
      let best = null; let bestD = Infinity;
      for (let j = 0; j < far.length; j++) {
        const s = far[j];
        if (chain.includes(s)) continue;
        const d = (s.x - far[idx].x) ** 2 + (s.y - far[idx].y) ** 2;
        if (d > 0.004 && d < bestD) { bestD = d; best = j; }
      }
      if (best === null) break;
      idx = best;
    }
    constellations.push(chain);
  }

  const DEPTH_SHIFT = [6, 12, 22]; // max px of pointer parallax per layer
  const DRIFT = [4, 7, 11];        // px of slow ambient drift per layer

  let w = 0, h = 0, dpr = 1;
  function resize() {
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    w = canvas.clientWidth; h = canvas.clientHeight;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  resize();
  window.addEventListener('resize', () => { resize(); if (reduced) draw(0, 0, 0); });

  // pointer target in [-1, 1], smoothed each frame
  let tx = 0, ty = 0, px = 0, py = 0;
  window.addEventListener('pointermove', (e) => {
    tx = (e.clientX / w) * 2 - 1;
    ty = (e.clientY / h) * 2 - 1;
  });

  function starPos(s, t, ox, oy) {
    const drift = DRIFT[s.depth];
    const dx = Math.sin(t * 0.00006 + s.ph) * drift;
    const dy = Math.cos(t * 0.00005 + s.ph * 1.7) * drift * 0.6;
    return [
      s.x * w + dx - ox * DEPTH_SHIFT[s.depth],
      s.y * h + dy - oy * DEPTH_SHIFT[s.depth],
    ];
  }

  function draw(t, ox, oy) {
    ctx.clearRect(0, 0, w, h);

    // constellation lines ride the far layer
    ctx.strokeStyle = LINE;
    ctx.globalAlpha = 0.4;
    ctx.lineWidth = 1;
    for (const chain of constellations) {
      ctx.beginPath();
      chain.forEach((s, i) => {
        const [x, y] = starPos(s, t, ox, oy);
        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
      });
      ctx.stroke();
    }

    for (const s of stars) {
      const [x, y] = starPos(s, t, ox, oy);
      const a = reduced ? s.base : s.base * (0.75 + 0.25 * Math.sin(t * 0.001 * s.tw + s.ph));
      ctx.globalAlpha = Math.max(0.05, a);
      ctx.fillStyle = s.gold ? GOLD : WHITE;
      ctx.beginPath();
      ctx.arc(x, y, s.r, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  if (reduced) { draw(0, 0, 0); return; }

  function frame(t) {
    px += (tx - px) * 0.05;
    py += (ty - py) * 0.05;
    draw(t, px, py);
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}
