// Star Tournaments · views + hash router.

import { TOURNAMENTS, TEAMS, PLAYERS, TFT_STANDINGS, tournament, matchesFor, match } from './data.js';
import { startStarfield } from './starfield.js';
import { STAR, glyph, starRule } from './ui-kit.js';
import * as pages from './pages.js';
import { renderAdmin } from './admin.js';

const view = document.getElementById('view');

function sideName(s) { return typeof s === 'number' ? TEAMS[s] : s; }

function matchLabel(m) {
  const t = tournament(m.t);
  if (t.format === 'series') return { long: `GAME ${m.round}`, short: `G${m.round}` };
  if (t.format === 'points') return { long: `LOBBY ${m.round}`, short: `L${m.round}` };
  const maxR = Math.max(...matchesFor(m.t).map((x) => x.round));
  if (m.round === maxR) return { long: 'GRAND FINAL', short: 'F' };
  if (m.round === maxR - 1) return { long: `SEMIFINAL ${m.slot}`, short: `SF${m.slot}` };
  return { long: `QUARTERFINAL ${m.slot}`, short: `QF${m.slot}` };
}

function pageHead(t, titleOverride) {
  const chip = t.status === 'live'
    ? `<span class="chip chip-live">LIVE</span>`
    : t.status === 'upcoming'
      ? `<span class="chip" style="color: var(--text-2);">${t.dates.split(' ')[0]} ${t.dates.split(' ')[1]}</span>`
      : `<span class="chip chip-done">COMPLETED</span>`;
  return `
    <div class="page-head rise">
      <div class="page-head-left">
        ${glyph(t.glyph, 52)}
        <div>
          <div class="page-title">${titleOverride || t.name}</div>
          <div class="page-meta">${t.game.toUpperCase()} · ${t.formatLabel} · ${t.size} · ${t.dates} · ${t.prize} POOL</div>
        </div>
      </div>
      <div style="display: flex; align-items: baseline; gap: 24px;">${chip}<span class="session">SESSION ${t.code}</span></div>
    </div>`;
}

/* ---------- home ---------- */

function renderHome() {
  const live = tournament('SS');
  const next = tournament('FI');
  const done = TOURNAMENTS.filter((t) => t.status === 'completed');

  const heroConstellation = `
    <svg width="430" height="270" viewBox="0 0 430 270" aria-hidden="true">
      <path d="M 60 220 L 130 90 L 205 160 L 290 60 L 368 130" fill="none" stroke="var(--line-strong)" stroke-width="1.4"></path>
      <circle cx="60" cy="220" r="3.4" fill="var(--text)"></circle>
      <circle cx="130" cy="90" r="4.2" fill="var(--text)"></circle>
      <circle cx="205" cy="160" r="3" fill="var(--text)"></circle>
      <path d="M290 47 L293 57 L303 60 L293 63 L290 73 L287 63 L277 60 L287 57 Z" fill="var(--gold)"></path>
      <circle cx="368" cy="130" r="3.4" fill="var(--text)"></circle>
      <text x="290" y="95" text-anchor="middle" font-family="Martian Mono, monospace" font-size="10" letter-spacing="2" fill="var(--text-3)">SS</text>
    </svg>`;

  view.innerHTML = `
    <div class="hero rise">
      <div>
        <div class="hero-tag"><span class="livedot" style="display:inline-flex;">${STAR(11)}</span>LIVE NOW</div>
        <div class="hero-title">${live.name}</div>
        <div class="hero-meta">${live.game.toUpperCase()} · ${live.formatLabel} · ${live.prize} POOL · AUG 20–23</div>
        <div class="hero-sub">Grand Final · Triple T's Sahurs vs Elements of Harmony</div>
        <a class="btn-gold" href="#/match/18">WATCH THE FINAL · AUG 23 · 18:00 &#8594;</a>
      </div>
      ${heroConstellation}
    </div>

    <div class="rise rise-2" style="margin-top: 40px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">UP NEXT ${starRule()}</div>
      <a class="uprow t-row" style="border-bottom: 1px solid var(--line);" href="#/event/FI">
        ${glyph(next.glyph, 40)}
        <div class="uprow-name">${next.name}</div>
        <div style="font-size: 13px; color: var(--text-2);">${next.game} · Single Elimination</div>
        <div class="mono" style="font-size: 12px; color: var(--text-2);">${next.dates}</div>
        <div class="num">${next.prize}</div>
        <div class="right" style="font-size: 13px; color: var(--text-2);">${next.note}</div>
      </a>
    </div>

    <div class="rise rise-3" style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px;">SEASON ARCHIVE ${starRule()}</div>
      <div class="tiles">
        ${done.map((t) => `
          <a class="tile" href="#/event/${t.code}">
            <div class="tile-top">${glyph(t.glyph, 34)}<span class="tile-date">${t.month}</span></div>
            <div class="tile-name">${t.name}</div>
            <div class="tile-meta">${t.game.toUpperCase()} · ${t.size} · ${t.prize}</div>
            <div class="tile-rule"></div>
            <div class="tile-champ">${STAR(10)}${t.champion}</div>
          </a>`).join('')}
      </div>
    </div>`;
}

/* ---------- event pages ---------- */

function cellSide(side, won) {
  return `
    <div class="mcell-side ${won ? 'win' : 'lose'}">
      <div class="mcell-name">${sideName(side[0])}</div>
      <div class="mcell-score">${side[1]}</div>
    </div>`;
}

function matchCell(m) {
  const lbl = matchLabel(m);
  if (!m.sides && !m.solo && !m.lobby) {
    return `
      <div class="mcell">
        <div class="mcell-side lose"><div class="mcell-name">${m.hint ? m.hint.split(' vs ')[0] : 'TBD'}</div><div class="mcell-score">–</div></div>
        <div class="mcell-rule"></div>
        <div class="mcell-side lose"><div class="mcell-name">${m.hint ? m.hint.split(' vs ')[1] : 'TBD'}</div><div class="mcell-score">–</div></div>
        <div class="mcell-foot">${m.t}-${lbl.short} · ${m.time}</div>
      </div>`;
  }
  const sides = m.sides || m.solo;
  return `
    <a class="mcell" href="#/match/${m.id}">
      ${cellSide(sides[0], true)}
      <div class="mcell-rule"></div>
      ${cellSide(sides[1], false)}
      <div class="mcell-foot">${m.t}-${lbl.short} · ${m.time}</div>
    </a>`;
}

function renderElim(t) {
  const ms = matchesFor(t.code);
  const maxR = Math.max(...ms.map((m) => m.round));
  const names = maxR === 3 ? ['QUARTERFINALS', 'SEMIFINALS', 'FINAL'] : ['SEMIFINALS', 'FINAL'];
  const cols = [];
  for (let r = 1; r <= maxR; r++) {
    const inRound = ms.filter((m) => m.round === r).sort((a, b) => a.slot - b.slot);
    cols.push(`
      <div class="b-col">
        <div class="b-col-label">${names[r - 1]}</div>
        <div class="b-col-body">${inRound.map(matchCell).join('')}</div>
      </div>`);
  }
  if (t.champion) {
    cols.push(`
      <div class="b-col">
        <div class="b-col-label champ">CHAMPION</div>
        <div class="champ-box">
          ${STAR(24)}
          <div class="champ-name">${t.champion}</div>
          <div class="champ-meta">${t.championMeta || ''}</div>
          <div class="champ-prize">${t.championPrize || ''}</div>
        </div>
      </div>`);
  }
  const n = cols.length;
  return `<div class="bracket rise rise-2" style="grid-template-columns: repeat(${n}, 1fr);">${cols.join('')}</div>`;
}

function renderPoints() {
  const grid = '70px minmax(0, 1fr) 90px 90px 130px 110px 110px';
  const maxPts = Math.max(...TFT_STANDINGS.map((r) => r[4]));
  return `
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>POS</div><div>PLAYER</div>
        <div class="right">L1</div><div class="right">L2</div>
        <div class="right">PTS</div><div class="right">GAP</div><div class="right">INT</div>
      </div>
      ${TFT_STANDINGS.map(([pos, ign, l1, l2, pts, gap, int, note]) => `
        <div class="t-row clickable" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 15px; ${pos === 1 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${pos}</div>
          <div style="display: flex; align-items: baseline; gap: 14px;">
            <span style="font-weight: ${pos === 1 ? 800 : 700}; font-stretch: 115%; font-size: ${pos === 1 ? 24 : 20}px; text-transform: uppercase;">${ign}</span>
            ${note ? `${pos === 1 ? STAR(12) : ''}<span class="mono" style="font-size: 10px; letter-spacing: 0.18em; color: ${pos === 1 ? 'var(--gold)' : 'var(--text-3)'};">${note}</span>` : ''}
          </div>
          <div class="num">${l1}</div>
          <div class="num">${l2}</div>
          <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 5px;">
            <span class="num-strong">${pts}</span>
            <span class="bar-track"><span class="bar-fill ${pos === 1 ? 'gold' : ''}" style="display: block; width: ${Math.round((pts / maxPts) * 100)}%;"></span></span>
          </div>
          <div class="num" style="color: var(--text-2);">${gap === null ? '–' : gap}</div>
          <div class="num" style="color: var(--text-2);">${int === null ? '–' : int}</div>
        </div>`).join('')}
      <div class="footnote mono" style="display: flex; justify-content: space-between; padding-top: 20px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">
        <span>L1 / L2 = LOBBY FINISH · PTS = 9 &#8722; PLACEMENT, SUMMED</span>
        <span>GAP = TO LEADER · INT = TO PLAYER AHEAD</span>
      </div>
    </div>`;
}

function renderSeries(t) {
  const ms = matchesFor(t.code);
  return `
    <div class="bracket rise rise-2" style="grid-template-columns: repeat(2, 1fr);">
      <div class="b-col">
        <div class="b-col-label">THE SERIES</div>
        <div class="b-col-body" style="gap: 20px; justify-content: center;">${ms.map(matchCell).join('')}</div>
      </div>
      <div class="b-col">
        <div class="b-col-label champ">CHAMPION</div>
        <div class="champ-box">
          ${STAR(24)}
          <div class="champ-name">${t.champion}</div>
          <div class="champ-meta">${t.championMeta || ''}</div>
          <div class="champ-prize">${t.championPrize || ''}</div>
        </div>
      </div>
    </div>`;
}

function renderEvent(code, titleOverride) {
  const t = tournament(code);
  if (!t) return renderHome();
  let body = '';
  if (t.format === 'points') body = renderPoints();
  else if (t.format === 'series') body = renderSeries(t);
  else body = renderElim(t);
  view.innerHTML = pageHead(t, titleOverride) + body;
}

/* ---------- match page ---------- */

function renderMatch(id) {
  const m = match(id);
  if (!m) return renderHome();
  const t = tournament(m.t);
  const lbl = matchLabel(m);

  let board = '';
  let table = '';

  if (m.lobby) {
    board = `<div class="scoreboard rise rise-2" style="grid-template-columns: 1fr;"><div class="sb-mid"><div class="sb-score" style="font-size: 44px;">LOBBY ${m.round}</div><div class="sb-state">8 PLAYERS · POINTS BY PLACEMENT</div></div></div>`;
    const grid = '90px minmax(0, 1fr) 130px';
    table = `
      <div class="rise rise-3" style="margin-top: 44px;">
        <div class="t-head" style="grid-template-columns: ${grid};"><div>PLACE</div><div>PLAYER</div><div class="right">POINTS</div></div>
        ${m.lobby.map(([ign, place, pts]) => `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 15px; ${place === 1 ? 'color: var(--gold); font-weight: 700;' : 'color: var(--text-2);'}">${place}</div>
            <div style="font-weight: ${place === 1 ? 800 : 600}; font-stretch: 112%; font-size: 17px; text-transform: uppercase;">${ign}</div>
            <div class="num-strong">${pts}</div>
          </div>`).join('')}
      </div>`;
  } else if (!m.sides && !m.solo) {
    const names = m.hint ? m.hint.split(' vs ') : ['TBD', 'TBD'];
    board = `
      <div class="scoreboard rise rise-2">
        <div class="sb-team left"><div class="sb-name">${names[0]}</div></div>
        <div class="sb-mid"><div class="sb-score" style="color: var(--text-3);">VS</div><div class="sb-state">${m.time} · NOT YET PLAYED</div></div>
        <div class="sb-team right"><div class="sb-name">${names[1]}</div></div>
      </div>`;
  } else {
    const sides = m.sides || m.solo;
    const isFinal = lbl.short === 'F';
    const aName = sideName(sides[0][0]);
    const bName = sideName(sides[1][0]);
    board = `
      <div class="scoreboard rise rise-2">
        <div class="sb-team left">
          <div class="sb-name">${aName}</div>
          <div class="sb-tag ${isFinal ? 'champ' : ''}">${isFinal ? STAR(12) + 'CHAMPION' : 'WINNER'}</div>
        </div>
        <div class="sb-mid">
          <div class="sb-score"><span class="${isFinal ? 'w' : ''}">${sides[0][1]}</span><span class="sep">&#8211;</span><span>${sides[1][1]}</span></div>
          <div class="sb-state">FULL TIME</div>
        </div>
        <div class="sb-team right">
          <div class="sb-name lose">${bName}</div>
          <div class="sb-tag">${isFinal ? 'RUNNER-UP' : 'ELIMINATED FROM THIS PATH'}</div>
        </div>
      </div>`;

    if (m.stats) {
      const grid = 'minmax(0, 1fr) 240px 90px 90px 90px 110px';
      const winTeam = sides[0][0];
      const rows = [...m.stats].sort((a, b) => b[1] - a[1]);
      const winRows = rows.filter(([pid]) => PLAYERS[pid][1] === winTeam);
      const loseRows = rows.filter(([pid]) => PLAYERS[pid][1] !== winTeam);
      const row = ([pid, k, d, a, s], losing) => `
        <div class="t-row ${losing ? 'row-lose' : ''}" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700; font-size: 16px;">${PLAYERS[pid][0]}</div>
          <div class="t2" style="font-size: 13px; color: var(--text-2);">${TEAMS[PLAYERS[pid][1]]}</div>
          <div class="num" style="font-weight: 700;">${k}</div>
          <div class="num" style="color: var(--text-2);">${d}</div>
          <div class="num" style="color: var(--text-2);">${a}</div>
          <div class="num">${s}</div>
        </div>`;
      table = `
        <div class="rise rise-3" style="margin-top: 44px;">
          <div class="t-head" style="grid-template-columns: ${grid};">
            <div>PLAYER</div><div>TEAM</div>
            <div class="right">K</div><div class="right">D</div><div class="right">A</div><div class="right">SCORE</div>
          </div>
          ${winRows.map((r) => row(r, false)).join('')}
          ${loseRows.map((r) => row(r, true)).join('')}
        </div>`;
    }
  }

  view.innerHTML = `
    ${pageHead(t, lbl.long)}
    ${board}
    ${table}
    <div class="rise rise-4 mono" style="display: flex; justify-content: space-between; padding-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">
      <a href="#/event/${t.code}" style="color: var(--text-3);">&#8592; BACK TO ${t.name.toUpperCase()}</a>
      <span>SESSION ${t.code}-${lbl.short} · ${m.time}</span>
    </div>`;
}

/* ---------- matches index ---------- */

function renderMatches() {
  const grid = '110px minmax(0, 1fr) 160px 120px';
  const blocks = TOURNAMENTS.filter((t) => matchesFor(t.code).length).map((t) => {
    const rows = matchesFor(t.code).map((m) => {
      const lbl = matchLabel(m);
      const played = m.sides || m.solo || m.lobby;
      const versus = m.lobby
        ? '8 player lobby'
        : played
          ? `${sideName((m.sides || m.solo)[0][0])} def. ${sideName((m.sides || m.solo)[1][0])}`
          : (m.hint || 'TBD vs TBD');
      const score = m.lobby ? '·' : played ? `${(m.sides || m.solo)[0][1]}&#8211;${(m.sides || m.solo)[1][1]}` : '·';
      const inner = `
        <div class="mono" style="font-size: 12px; color: var(--text-3);">${t.code}-${lbl.short}</div>
        <div style="font-weight: ${played ? 700 : 500}; font-size: 15px; ${played ? '' : 'color: var(--text-2);'}">${versus}</div>
        <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
        <div class="num" style="font-weight: 700;">${score}</div>`;
      return played
        ? `<a class="t-row" style="grid-template-columns: ${grid};" href="#/match/${m.id}">${inner}</a>`
        : `<div class="t-row" style="grid-template-columns: ${grid};">${inner}</div>`;
    }).join('');
    return `
      <div style="margin-top: 38px;">
        <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
          ${t.name.toUpperCase()} ${starRule()}
        </div>
        ${rows}
      </div>`;
  }).join('');

  view.innerHTML = `
    <div class="page-head rise">
      <div class="page-head-left">
        <div>
          <div class="page-title">Matches</div>
          <div class="page-meta">EVERY SESSION ACROSS THE 2026 SEASON</div>
        </div>
      </div>
    </div>
    <div class="rise rise-2">${blocks}</div>`;
}

/* ---------- roles ---------- */

const ROLE_PAGES = {
  player: [['#/me/profile', 'MY PROFILE'], ['#/me/history', 'MATCH HISTORY']],
  org: [['#/org/payouts', 'TEAM PAYOUTS']],
  staff: [['#/staff/ops', 'RUN SHEET'], ['#/staff/deliverables', 'DELIVERABLES'], ['#/staff/integrity', 'DATA QUALITY']],
  admin: [['#/admin', 'FINANCIALS · PAYMENTS · MEMBERS']],
  sponsor: [['#/sponsor', 'SPONSOR PORTAL']],
  creator: [['#/creator', 'CREATOR PORTAL']],
};

const ROLE_TAGS = {
  player: 'SIGNED IN AS AUS#MTB', org: 'SIGNED IN AS QOR', staff: 'SIGNED IN AS HEAD CASTER',
  admin: 'SIGNED IN AS MTB EVENTS ADMIN', sponsor: 'SIGNED IN AS RED BULL', creator: 'SIGNED IN AS REVRZD',
};

const roleSelect = document.getElementById('role');
const rolebar = document.getElementById('rolebar');
let role = 'audience';

function setRole(r, navigate) {
  role = r;
  roleSelect.value = r;
  if (r === 'audience' || !ROLE_PAGES[r]) {
    rolebar.className = 'rolebar';
    rolebar.innerHTML = '';
  } else {
    rolebar.className = 'rolebar on';
    rolebar.innerHTML = `<span class="rb-tag">${ROLE_TAGS[r]}</span>` +
      ROLE_PAGES[r].map(([href, label]) => `<a href="${href}" data-rb="${href}">${label}</a>`).join('');
  }
  if (navigate) location.hash = r === 'audience' ? '#/' : ROLE_PAGES[r][0][0];
}

roleSelect.addEventListener('change', () => setRole(roleSelect.value, true));

const ROUTE_ROLE = {
  'me': 'player', 'org': 'org', 'staff': 'staff', 'admin': 'admin', 'sponsor': 'sponsor', 'creator': 'creator',
};

/* ---------- router ---------- */

function setNav(name) {
  document.querySelectorAll('.nav a').forEach((a) => {
    a.classList.toggle('active', a.dataset.nav === name);
  });
  document.querySelectorAll('.rolebar a').forEach((a) => {
    a.classList.toggle('active', a.dataset.rb === location.hash);
  });
}

function route() {
  const hash = location.hash.replace(/^#\//, '');
  const [page, arg] = hash.split('/');
  window.scrollTo(0, 0);

  const impliedRole = ROUTE_ROLE[page];
  if (impliedRole && role !== impliedRole) setRole(impliedRole, false);

  if (page === 'event' && arg) { setNav('events'); renderEvent(arg); }
  else if (page === 'match' && arg) { setNav('matches'); renderMatch(arg); }
  else if (page === 'matches') { setNav('matches'); renderMatches(); }
  else if (page === 'standings') { setNav('standings'); renderEvent('TF', 'Classification'); }
  else if (page === 'rosters') { setNav('rosters'); pages.renderRosters(view); }
  else if (page === 'players') { setNav('players'); pages.renderPlayers(view); }
  else if (page === 'me' && arg === 'profile') { setNav(''); pages.renderProfile(view); }
  else if (page === 'me' && arg === 'history') { setNav(''); pages.renderHistory(view); }
  else if (page === 'org' && arg === 'payouts') { setNav(''); pages.renderOrgPayouts(view); }
  else if (page === 'staff' && arg === 'ops') { setNav(''); pages.renderOps(view); }
  else if (page === 'staff' && arg === 'deliverables') { setNav(''); pages.renderDeliverables(view); }
  else if (page === 'staff' && arg === 'integrity') { setNav(''); pages.renderIntegrity(view); }
  else if (page === 'sponsor') { setNav(''); pages.renderSponsor(view); }
  else if (page === 'creator') { setNav(''); pages.renderCreator(view); }
  else if (page === 'admin') { setNav(''); renderAdmin(view); }
  else { setNav('events'); renderHome(); }
}

window.addEventListener('hashchange', route);

/* ---------- boot ---------- */

startStarfield(document.getElementById('starfield'));

const clock = document.getElementById('clock');
function tick() {
  const d = new Date();
  const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  clock.textContent = `${d.getDate()} ${months[d.getMonth()]} · ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}
tick();
setInterval(tick, 30000);

route();
