// Star Tournaments · views + hash router.

import { GAMES, TOURNAMENTS, MATCHES, TEAMS, PLAYERS, tftStandings, tournament, matchesFor, match } from './data.js';
import { startStarfield } from './starfield.js';
import { STAR, glyph, starRule, plainHead, gameTabs } from './ui-kit.js';
import * as pages from './pages.js';
import { renderAdmin } from './admin.js';
import { renderConsole } from './console.js';
import { renderCreatorsAdmin } from './creators-admin.js';
import { renderSiteAdmin } from './site-admin.js';
import { renderCheckin } from './checkin.js';

const view = document.getElementById('view');
const GAME_ENTRIES = Object.entries(GAMES).map(([key, game]) => [key, game.label]);

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function sideName(s) { return typeof s === 'number' ? TEAMS[s] : s; }

function playerIdForIgn(ign) {
  const hit = Object.entries(PLAYERS).find(([, p]) => p[0] === ign);
  return hit ? Number(hit[0]) : null;
}

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
      <div style="display: flex; align-items: baseline; gap: 24px;">${chip}</div>
    </div>`;
}

/* ---------- home ---------- */

function renderHome() {
  const featured = TOURNAMENTS.find((t) => t.status === 'live') ||
    TOURNAMENTS.find((t) => t.status === 'upcoming') ||
    TOURNAMENTS[0];
  const featureMatches = matchesFor(featured.code);
  const final = featureMatches.length
    ? featureMatches.reduce((best, m) => !best || m.round > best.round ? m : best, null)
    : null;
  const next = TOURNAMENTS.find((t) => t.status === 'upcoming' && t !== featured);
  const done = TOURNAMENTS.filter((t) => t.status === 'completed');
  const heroTag = featured.status === 'live'
    ? `<div class="hero-tag"><span class="livedot" style="display:inline-flex;">${STAR(11)}</span>LIVE NOW</div>`
    : '<div class="hero-tag">UP NEXT</div>';
  const heroPrimary = final
    ? final.sides
      ? `<a class="btn-gold" href="#/event/${featured.code}">VIEW THE RESULT &#8594;</a>`
      : `<a class="btn-gold" href="#/match/${final.id}">WATCH THE FINAL · ${final.time} &#8594;</a>`
    : `<a class="btn-gold" href="#/event/${featured.code}">VIEW EVENT &#8594;</a>`;
  const heroBracket = final && !final.sides
    ? `<a class="btn-quiet" href="#/event/${featured.code}">VIEW BRACKET &#8594;</a>`
    : '';
  const heroButton = `<div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">${heroPrimary}${heroBracket}</div>`;

  const heroConstellation = `
    <svg width="430" height="270" viewBox="0 0 430 270" aria-hidden="true">
      <path d="M 60 220 L 130 90 L 205 160 L 290 60 L 368 130" fill="none" stroke="var(--line-strong)" stroke-width="1.4"></path>
      <circle cx="60" cy="220" r="3.4" fill="var(--text)"></circle>
      <circle cx="130" cy="90" r="4.2" fill="var(--text)"></circle>
      <circle cx="205" cy="160" r="3" fill="var(--text)"></circle>
      <path d="M290 47 L293 57 L303 60 L293 63 L290 73 L287 63 L277 60 L287 57 Z" fill="var(--gold)"></path>
      <circle cx="368" cy="130" r="3.4" fill="var(--text)"></circle>
    </svg>`;
  const heroArt = featured.code === 'SS'
    ? heroConstellation
    : `<div style="display: flex; align-items: center; justify-content: center;">${glyph(featured.glyph, 240)}</div>`;

  view.innerHTML = `
    <div class="hero rise">
      <div>
        ${heroTag}
        <a class="hero-title" style="display: block; color: inherit;" href="#/event/${featured.code}">${featured.name}</a>
        <div class="hero-meta">${featured.game.toUpperCase()} · ${featured.formatLabel} · ${featured.prize} POOL · ${featured.dates}</div>
        <div class="hero-sub">${featured.note}</div>
        ${heroButton}
      </div>
      ${heroArt}
    </div>

    ${next ? `<div class="rise rise-2" style="margin-top: 40px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">UP NEXT ${starRule()}</div>
      <a class="uprow t-row" style="border-bottom: 1px solid var(--line);" href="#/event/${next.code}">
        ${glyph(next.glyph, 40)}
        <div class="uprow-name">${next.name}</div>
        <div style="font-size: 13px; color: var(--text-2);">${next.game} · ${next.formatLabel}</div>
        <div class="mono" style="font-size: 12px; color: var(--text-2);">${next.dates}</div>
        <div class="num">${next.prize}</div>
        <div class="right" style="font-size: 13px; color: var(--text-2);">${next.note}</div>
      </a>
    </div>` : ''}

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
        <div class="mcell-foot">${lbl.long} · ${m.time}</div>
      </div>`;
  }
  const sides = m.sides || m.solo;
  return `
    <a class="mcell" href="#/match/${m.id}">
      ${cellSide(sides[0], true)}
      <div class="mcell-rule"></div>
      ${cellSide(sides[1], false)}
      <div class="mcell-foot">${lbl.long} · ${m.time}</div>
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

function renderPoints(code = 'TF') {
  const grid = '70px minmax(0, 1fr) 90px 90px 130px 110px 110px';
  const rows = tftStandings(code);
  const maxPts = Math.max(...rows.map((r) => r[4]), 1);
  return `
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>POS</div><div>PLAYER</div>
        <div class="right">L1</div><div class="right">L2</div>
        <div class="right">PTS</div><div class="right">GAP</div><div class="right">INT</div>
      </div>
      ${rows.map(([pos, ign, l1, l2, pts, gap, int, note, pid]) => `
        <a class="t-row clickable" href="${pid ? `#/player/${pid}` : '#/players/tft'}" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 15px; ${pos === 1 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${pos}</div>
          <div style="display: flex; align-items: baseline; gap: 14px;">
            <span style="font-weight: ${pos === 1 ? 800 : 700}; font-stretch: 115%; font-size: ${pos === 1 ? 24 : 20}px; text-transform: uppercase;">${esc(ign)}</span>
            ${note ? `${pos === 1 ? STAR(12) : ''}<span class="mono" style="font-size: 10px; letter-spacing: 0.18em; color: ${pos === 1 ? 'var(--gold)' : 'var(--text-3)'};">${esc(note)}</span>` : ''}
          </div>
          <div class="num">${l1 === null ? '–' : l1}</div>
          <div class="num">${l2 === null ? '–' : l2}</div>
          <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 5px;">
            <span class="num-strong">${pts}</span>
            <span class="bar-track"><span class="bar-fill ${pos === 1 ? 'gold' : ''}" style="display: block; width: ${Math.round((pts / maxPts) * 100)}%;"></span></span>
          </div>
          <div class="num" style="color: var(--text-2);">${gap === null ? '–' : gap}</div>
          <div class="num" style="color: var(--text-2);">${int === null ? '–' : int}</div>
        </a>`).join('')}
      <div class="footnote mono" style="display: flex; justify-content: space-between; padding-top: 20px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">
        <span>L1 / L2 = LOBBY FINISH · PTS = 9 &#8722; PLACEMENT, SUMMED</span>
        <span>GAP = TO LEADER · INT = TO PLAYER AHEAD</span>
      </div>
    </div>`;
}

function renderValorantStandings() {
  const grid = '70px minmax(0,1fr) 90px 90px 130px 130px';
  const rows = new Map();
  const rowFor = (teamId) => {
    const row = rows.get(teamId) || { id: teamId, w: 0, l: 0, rw: 0, titles: 0 };
    rows.set(teamId, row);
    return row;
  };

  MATCHES
    .filter((m) =>
      GAMES.valorant.codes.includes(m.t) &&
      m.sides &&
      m.sides.every(([teamId]) => typeof teamId === 'number')
    )
    .forEach((m) => {
      const winner = rowFor(m.sides[0][0]);
      const loser = rowFor(m.sides[1][0]);
      winner.w += 1;
      loser.l += 1;
      winner.rw += m.sides[0][1];
      loser.rw += m.sides[1][1];
    });

  TOURNAMENTS
    .filter((t) => t.game === GAMES.valorant.name && t.champion)
    .forEach((t) => {
      const hit = Object.entries(TEAMS).find(([, name]) => name === t.champion);
      if (hit && rows.has(Number(hit[0]))) rows.get(Number(hit[0])).titles += 1;
    });

  const sorted = [...rows.values()].sort((a, b) => b.titles - a.titles || b.w - a.w || b.rw - a.rw);

  return `
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>POS</div><div>TEAM</div>
        <div class="right">W</div><div class="right">L</div><div class="right">RW</div><div class="right">TITLES</div>
      </div>
      ${sorted.map((r, i) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 15px; ${i === 0 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${i + 1}</div>
          <div style="font-weight: 700; font-size: 16px;"><a href="#/team/${r.id}" style="color: inherit;">${TEAMS[r.id]}</a></div>
          <div class="num">${r.w}</div>
          <div class="num">${r.l}</div>
          <div class="num">${r.rw}</div>
          <div class="right">${r.titles ? Array.from({ length: r.titles }, () => STAR(10)).join('') : '–'}</div>
        </div>`).join('')}
    </div>`;
}

function renderRocketLeagueStandings() {
  const grid = '70px minmax(0,1fr) 90px 90px 130px';
  const rows = new Map();
  const rowFor = (ign) => {
    const titles = TOURNAMENTS.filter((t) => t.game === GAMES.rl.name && t.champion === ign).length;
    const row = rows.get(ign) || { ign, id: playerIdForIgn(ign), w: 0, l: 0, titles };
    rows.set(ign, row);
    return row;
  };

  MATCHES
    .filter((m) => GAMES.rl.codes.includes(m.t) && m.solo)
    .forEach((m) => {
      rowFor(m.solo[0][0]).w += 1;
      rowFor(m.solo[1][0]).l += 1;
    });

  const sorted = [...rows.values()].sort((a, b) => b.titles - a.titles || b.w - a.w);

  return `
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>POS</div><div>PLAYER</div>
        <div class="right">W</div><div class="right">L</div><div class="right">TITLES</div>
      </div>
      ${sorted.map((r, i) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 15px; ${i === 0 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${i + 1}</div>
          <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${r.id}" style="color: inherit;">${esc(r.ign)}</a></div>
          <div class="num">${r.w}</div>
          <div class="num">${r.l}</div>
          <div class="right">${r.titles ? Array.from({ length: r.titles }, () => STAR(10)).join('') : '–'}</div>
        </div>`).join('')}
    </div>`;
}

function renderStandings(gameKey = 'valorant') {
  const key = GAMES[gameKey] ? gameKey : 'valorant';
  const body = key === 'tft'
    ? renderPoints('TF')
    : key === 'rl'
      ? renderRocketLeagueStandings()
      : renderValorantStandings();

  view.innerHTML = `
    ${plainHead('Standings', `${GAMES[key].label} · 2026 SEASON`, 'AUDIENCE')}
    ${gameTabs('standings', key, GAME_ENTRIES)}
    ${body}`;
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
  if (t.format === 'points') body = renderPoints(t.code);
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
        ${m.lobby.map(([ign, place, pts]) => {
          const pid = playerIdForIgn(ign);
          return `
            <div class="t-row" style="grid-template-columns: ${grid};">
              <div class="mono" style="font-size: 15px; ${place === 1 ? 'color: var(--gold); font-weight: 700;' : 'color: var(--text-2);'}">${place}</div>
              <div style="font-weight: ${place === 1 ? 800 : 600}; font-stretch: 112%; font-size: 17px; text-transform: uppercase;">${pid ? `<a href="#/player/${pid}" style="color: inherit;">${ign}</a>` : ign}</div>
              <div class="num-strong">${pts}</div>
            </div>`;
        }).join('')}
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
    const aPid = m.solo ? playerIdForIgn(aName) : null;
    const bPid = m.solo ? playerIdForIgn(bName) : null;
    const aNameHtml = m.sides && typeof sides[0][0] === 'number'
      ? `<a href="#/team/${sides[0][0]}" style="color: inherit;">${aName}</a>`
      : aPid ? `<a href="#/player/${aPid}" style="color: inherit;">${aName}</a>` : aName;
    const bNameHtml = m.sides && typeof sides[1][0] === 'number'
      ? `<a href="#/team/${sides[1][0]}" style="color: inherit;">${bName}</a>`
      : bPid ? `<a href="#/player/${bPid}" style="color: inherit;">${bName}</a>` : bName;
    board = `
      <div class="scoreboard rise rise-2">
        <div class="sb-team left">
          <div class="sb-name">${aNameHtml}</div>
          <div class="sb-tag ${isFinal ? 'champ' : ''}">${isFinal ? STAR(12) + 'CHAMPION' : 'WINNER'}</div>
        </div>
        <div class="sb-mid">
          <div class="sb-score"><span class="${isFinal ? 'w' : ''}">${sides[0][1]}</span><span class="sep">&#8211;</span><span>${sides[1][1]}</span></div>
          <div class="sb-state">FULL TIME</div>
        </div>
        <div class="sb-team right">
          <div class="sb-name lose">${bNameHtml}</div>
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
          <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${pid}" style="color: inherit;">${PLAYERS[pid][0]}</a></div>
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
      <span>${lbl.long} · ${m.time}</span>
    </div>`;
}

/* ---------- matches index ---------- */

function renderMatches(gameKey) {
  const key = GAMES[gameKey] ? gameKey : null;
  const codes = key ? GAMES[key].codes : null;
  const grid = '180px minmax(0, 1fr) 160px 120px';
  const blocks = TOURNAMENTS.filter((t) => matchesFor(t.code).length && (!codes || codes.includes(t.code))).map((t) => {
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
        <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
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
    ${gameTabs('matches', key, GAME_ENTRIES, true)}
    <div class="rise rise-2">${blocks}</div>`;
}

/* ---------- roles ---------- */

const ROLE_PAGES = {
  player: [['#/me/profile', 'MY PROFILE'], ['#/me/history', 'MATCH HISTORY']],
  org: [['#/org/payouts', 'TEAM PAYOUTS']],
  staff: [['#/staff/checkin', 'CHECK-IN'], ['#/staff/ops', 'RUN SHEET'], ['#/staff/deliverables', 'DELIVERABLES'], ['#/staff/integrity', 'DATA QUALITY']],
  admin: [['#/admin', 'DASHBOARD'], ['#/admin/ops', 'OPERATIONS'], ['#/admin/site', 'SITE EDITOR'], ['#/admin/creators', 'CREATORS']],
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

function updateFooterStats() {
  const footerStats = document.getElementById('footer-stats');
  if (!footerStats) return;
  const totalPrize = TOURNAMENTS.reduce((sum, t) => sum + (parseInt(String(t.prize || '').replace(/\D/g, ''), 10) || 0), 0);
  footerStats.innerHTML = `${TOURNAMENTS.length} EVENTS · ${totalPrize.toLocaleString('en-US')} IN PRIZES · <span class="gold">&#10022;</span> = CHAMPION`;
}

function route() {
  const hash = location.hash.replace(/^#\//, '');
  const [page, arg] = hash.split('/');
  window.scrollTo(0, 0);

  const impliedRole = ROUTE_ROLE[page];
  if (impliedRole && role !== impliedRole) setRole(impliedRole, false);

  if (page === 'event' && arg) { setNav('events'); renderEvent(arg); }
  else if (page === 'match' && arg) { setNav('matches'); renderMatch(arg); }
  else if (page === 'team' && arg) { setNav('rosters'); pages.renderTeam(view, arg); }
  else if (page === 'player' && arg) { setNav('players'); pages.renderPlayer(view, arg); }
  else if (page === 'matches') { setNav('matches'); renderMatches(arg); }
  else if (page === 'standings') { setNav('standings'); renderStandings(arg); }
  else if (page === 'rosters') { setNav('rosters'); pages.renderRosters(view, arg); }
  else if (page === 'players') { setNav('players'); pages.renderPlayers(view, arg); }
  else if (page === 'me' && arg === 'profile') { setNav(''); pages.renderProfile(view); }
  else if (page === 'me' && arg === 'history') { setNav(''); pages.renderHistory(view); }
  else if (page === 'org' && arg === 'payouts') { setNav(''); pages.renderOrgPayouts(view); }
  else if (page === 'staff' && arg === 'checkin') { setNav(''); renderCheckin(view); }
  else if (page === 'staff' && arg === 'ops') { setNav(''); pages.renderOps(view); }
  else if (page === 'staff' && arg === 'deliverables') { setNav(''); pages.renderDeliverables(view); }
  else if (page === 'staff' && arg === 'integrity') { setNav(''); pages.renderIntegrity(view); }
  else if (page === 'sponsor') { setNav(''); pages.renderSponsor(view); }
  else if (page === 'creator') { setNav(''); pages.renderCreator(view); }
  else if (page === 'admin' && arg === 'ops') { setNav(''); renderConsole(view); }
  else if (page === 'admin' && arg === 'site') { setNav(''); renderSiteAdmin(view); }
  else if (page === 'admin' && arg === 'creators') { setNav(''); renderCreatorsAdmin(view); }
  else if (page === 'admin') { setNav(''); renderAdmin(view); }
  else { setNav('events'); renderHome(); }
  updateFooterStats();
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
