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

// Platform logos as inline SVG (currentColor, so they inherit tag states).
export function platIcon(kind, size = 12) {
  if (kind === 'tw') {
    return `<svg width="${size}" height="${size}" viewBox="0 0 14 14" aria-label="Twitch"><path fill="currentColor" fill-rule="evenodd" d="M2.5 1 L1 3.5 V11 H3.9 V13.4 L6.3 11 H9 L13 7 V1 Z M6 3.6 h1.3 v3.2 H6 Z M9.2 3.6 h1.3 v3.2 H9.2 Z"></path></svg>`;
  }
  if (kind === 'ig') {
    return `<svg width="${size}" height="${size}" viewBox="0 0 14 14" aria-label="Instagram" fill="none" stroke="currentColor" stroke-width="1.3"><rect x="1.6" y="1.6" width="10.8" height="10.8" rx="3.1"></rect><circle cx="7" cy="7" r="2.6"></circle><circle cx="10.3" cy="3.7" r="0.8" fill="currentColor" stroke="none"></circle></svg>`;
  }
  return `<svg width="${size}" height="${size}" viewBox="0 0 14 14" aria-label="X"><path fill="currentColor" d="M1.6 1 H4.7 L7.4 4.9 L10.7 1 H12.6 L8.3 6.1 L13 13 H9.9 L6.8 8.5 L3 13 H1.1 L5.9 7.3 Z"></path></svg>`;
}

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

export function gameTabs(base, active, entries, includeAll = false) {
  const tabs = [
    includeAll ? `<a class="${!active ? 'tab active' : 'tab'}" href="#/${base}">ALL</a>` : '',
    ...entries.map(([key, label]) =>
      `<a class="${active === key ? 'tab active' : 'tab'}" href="#/${base}/${key}">${label}</a>`
    ),
  ].filter(Boolean).join('');
  return `<div class="tabs rise rise-2">${tabs}</div>`;
}
