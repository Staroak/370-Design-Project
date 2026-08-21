// Star Tournaments · shared rendering helpers.

export const STAR = (size = 10, color = 'var(--gold)') =>
  `<svg width="${size}" height="${size}" viewBox="0 0 12 12" aria-hidden="true"><path d="M6 0 L7.4 4.6 L12 6 L7.4 7.4 L6 12 L4.6 7.4 L0 6 L4.6 4.6 Z" fill="${color}"></path></svg>`;

export function glyph(g, size = 34) {
  const pts = g.pts;
  const upto = g.closed ? pts.length - 1 : pts.length;
  let d = '';
  for (let i = 0; i < upto; i++) d += `${i === 0 ? 'M' : 'L'} ${pts[i][0]} ${pts[i][1]} `;
  if (g.closed) d += 'Z';
  const dots = pts.map((p, i) =>
    i === g.gold
      ? `<circle cx="${p[0]}" cy="${p[1]}" r="2.6" fill="var(--gold)"></circle>`
      : `<circle cx="${p[0]}" cy="${p[1]}" r="2" fill="var(--text)"></circle>`
  ).join('');
  return `<svg width="${size}" height="${size}" viewBox="0 0 40 40" aria-hidden="true"><path d="${d}" fill="none" stroke="var(--line-strong)" stroke-width="1.2"></path>${dots}</svg>`;
}

export const starRule = () =>
  `<svg width="40" height="8" viewBox="0 0 40 8" aria-hidden="true"><line x1="0" y1="4" x2="30" y2="4" stroke="var(--line-strong)" stroke-width="1"></line><path d="M35 0.6 L35.9 3.1 L38.4 4 L35.9 4.9 L35 7.4 L34.1 4.9 L31.6 4 L34.1 3.1 Z" fill="var(--text-3)"></path></svg>`;

// A simple page header for role/utility pages (no tournament attached).
export function plainHead(title, meta, session) {
  return `
    <div class="page-head rise">
      <div class="page-head-left">
        <div>
          <div class="page-title">${title}</div>
          <div class="page-meta">${meta}</div>
        </div>
      </div>
      ${session ? `<span class="session">${session}</span>` : ''}
    </div>`;
}
