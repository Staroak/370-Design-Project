// Star Tournaments · role and utility pages.

import {
  GAMES,
  TEAMS,
  TEAM_META,
  PLAYERS,
  TOURNAMENTS,
  MATCHES,
  tftStandings,
  CREATORS,
  CREATOR_ASSIGNMENTS,
  DELIVERABLES,
  INTEGRITY,
  OPS,
  PORTAL,
  rosterOf,
  tournament,
  matchesFor,
  streamFor,
  setStream,
} from './data.js';
import { STAR, glyph, starRule, plainHead, gameTabs, platIcon } from './ui-kit.js';

const GAME_ENTRIES = Object.entries(GAMES).map(([key, game]) => [key, game.label]);
const dash = '–';

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function sideName(side) {
  return typeof side === 'number' ? TEAMS[side] : side;
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

function statusPill(status) {
  const ok = ['paid', 'fulfilled', 'active'].includes(String(status).toLowerCase());
  return `<span class="pill ${ok ? 'pill-ok' : 'pill-due'}">${String(status).toUpperCase()}</span>`;
}

export function renderRosters(container, gameKey = 'valorant') {
  const key = GAMES[gameKey] ? gameKey : 'valorant';
  const grid = '70px minmax(0, 1fr) 200px';
  const soloSection = (ids) => `
    <div style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        SOLO ENTRANTS ${starRule()}
      </div>
      ${ids.map((id, i) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 14px; color: var(--text-2);">${i + 1}</div>
          <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${id}" style="color: inherit;">${PLAYERS[id][0]}</a></div>
          <div class="right mono" style="font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">SOLO</div>
        </div>`).join('')}
    </div>`;

  if (key !== 'valorant') {
    container.innerHTML = `
      ${plainHead('Rosters', 'SOLO COMPETITORS · NO TEAM AFFILIATION', 'AUDIENCE')}
      ${gameTabs('rosters', key, GAME_ENTRIES)}
      <div class="rise rise-2">${soloSection(key === 'tft' ? [47, 48, 49, 50, 51, 52, 53, 54] : [55, 56])}</div>`;
    return;
  }

  const sections = Object.keys(TEAMS).map((teamId) => `
    <div style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        <a href="#/team/${teamId}" style="color: inherit;">${TEAMS[teamId].toUpperCase()}</a> ${starRule()}
      </div>
      ${rosterOf(Number(teamId)).map((p) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 14px; color: var(--text-2);">${p.jersey}</div>
          <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${p.id}" style="color: inherit;">${p.ign}</a></div>
          <div class="right mono" style="font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">${p.jersey <= 5 ? 'STARTER' : 'SUBSTITUTE'}</div>
        </div>`).join('')}
    </div>`).join('');

  container.innerHTML = `
    ${plainHead('Rosters', 'V_PUBLIC_ROSTERS · ACTIVE LINEUPS · SALARIES HIDDEN FROM PUBLIC VIEW', 'AUDIENCE')}
    ${gameTabs('rosters', key, GAME_ENTRIES)}
    <div class="rise rise-2">${sections}</div>`;
}

export function renderPlayers(container, gameKey = 'valorant') {
  const key = GAMES[gameKey] ? gameKey : 'valorant';

  if (key === 'tft') {
    const grid = '70px minmax(0,1fr) 120px 150px 150px';
    const rows = tftStandings('TF');
    container.innerHTML = `
      ${plainHead('Player Leaderboard', `V_PUBLIC_PLAYER_STATS · ${GAMES[key].label} · ALL SESSIONS`, 'AUDIENCE')}
      ${gameTabs('players', key, GAME_ENTRIES)}
      <div class="rise rise-2" style="margin-top: 36px;">
        <div class="t-head" style="grid-template-columns: ${grid};">
          <div>POS</div><div>PLAYER</div>
          <div class="right">LOBBIES</div><div class="right">TOTAL PTS</div><div class="right">BEST FINISH</div>
        </div>
        ${rows.map(([pos, ign, l1, l2, pts, , , , pid]) => `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 15px; ${pos === 1 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${pos}</div>
            <div style="font-weight: 700; font-size: 16px;"><a href="${pid ? `#/player/${pid}` : '#/players/tft'}" style="color: inherit;">${esc(ign)}</a></div>
            <div class="num">${[l1, l2].filter((value) => value !== null).length}</div>
            <div class="num-strong">${pts}</div>
            <div class="num">${Math.min(...[l1, l2].filter((value) => value !== null))}</div>
          </div>`).join('')}
      </div>`;
    return;
  }

  if (key === 'rl') {
    const grid = '70px minmax(0,1fr) 90px 90px 90px';
    const seen = new Set();
    const entrants = [];
    MATCHES
      .filter((m) => GAMES.rl.codes.includes(m.t) && m.solo)
      .forEach((m) => {
        m.solo.forEach(([ign]) => {
          if (!seen.has(ign)) {
            seen.add(ign);
            entrants.push(ign);
          }
        });
      });
    const rows = entrants.map((ign) => {
      const games = MATCHES.filter((m) => m.solo && m.solo.some(([rowIgn]) => rowIgn === ign));
      const hit = Object.entries(PLAYERS).find(([, p]) => p[0] === ign);
      return {
        ign,
        id: hit ? Number(hit[0]) : null,
        games: games.length,
        w: games.filter((m) => m.solo[0][0] === ign).length,
      };
    });

    container.innerHTML = `
      ${plainHead('Player Leaderboard', `V_PUBLIC_PLAYER_STATS · ${GAMES[key].label} · ALL SESSIONS`, 'AUDIENCE')}
      ${gameTabs('players', key, GAME_ENTRIES)}
      <div class="rise rise-2" style="margin-top: 36px;">
        <div class="t-head" style="grid-template-columns: ${grid};">
          <div>POS</div><div>PLAYER</div>
          <div class="right">GAMES</div><div class="right">W</div><div class="right">L</div>
        </div>
        ${rows.map((r, i) => `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 15px; ${i === 0 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${i + 1}</div>
            <div style="font-weight: 700; font-size: 16px;"><a href="${r.id ? `#/player/${r.id}` : '#/players/rl'}" style="color: inherit;">${esc(r.ign)}</a></div>
            <div class="num">${r.games}</div>
            <div class="num">${r.w}</div>
            <div class="num">${r.games - r.w}</div>
          </div>`).join('')}
      </div>`;
    return;
  }

  const grid = '70px minmax(0,1fr) 240px 70px 90px 90px 90px 110px';
  const totals = new Map();
  MATCHES.filter((m) => m.stats).forEach((m) => {
    m.stats.forEach(([pid, k, d, a]) => {
      const row = totals.get(pid) || { id: pid, kills: 0, deaths: 0, assists: 0, matches: 0 };
      row.kills += k;
      row.deaths += d;
      row.assists += a;
      row.matches += 1;
      totals.set(pid, row);
    });
  });
  const rows = [...totals.values()].sort((a, b) => b.kills - a.kills).slice(0, 15);

  container.innerHTML = `
    ${plainHead('Player Leaderboard', `V_PUBLIC_PLAYER_STATS · ${GAMES[key].label} · ALL SESSIONS`, 'AUDIENCE')}
    ${gameTabs('players', key, GAME_ENTRIES)}
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>RANK</div><div>PLAYER</div><div>TEAM</div>
        <div class="right">M</div><div class="right">K</div><div class="right">D</div><div class="right">A</div><div class="right">K/D</div>
      </div>
      ${rows.map((r, i) => {
        const p = PLAYERS[r.id];
        return `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 15px; ${i === 0 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">P${i + 1}</div>
            <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${r.id}" style="color: inherit;">${p[0]}</a></div>
            <div style="color: var(--text-2);"><a href="#/team/${p[1]}" style="color: inherit;">${TEAMS[p[1]]}</a></div>
            <div class="num">${r.matches}</div>
            <div class="num">${r.kills}</div>
            <div class="num">${r.deaths}</div>
            <div class="num">${r.assists}</div>
            <div class="num">${(r.deaths ? r.kills / r.deaths : 0).toFixed(2)}</div>
          </div>`;
      }).join('')}
    </div>`;
}

export function renderTeam(container, teamId) {
  const id = Number(teamId);
  const meta = TEAM_META[id];
  if (!TEAMS[id] || !meta) {
    container.innerHTML = plainHead('Team not found', '', '');
    return;
  }

  const teamMatches = MATCHES
    .filter((m) => m.sides && m.sides.some(([side]) => side === id))
    .sort((a, b) => a.id - b.id);
  const wins = teamMatches.filter((m) => m.sides[0][0] === id).length;
  const losses = teamMatches.length - wins;
  const roundsWon = teamMatches.reduce((sum, m) => {
    const side = m.sides.find(([sideId]) => sideId === id);
    return sum + side[1];
  }, 0);
  const champions = TOURNAMENTS.filter((t) => t.champion === TEAMS[id]).map((t) => t.name);
  const rosterGrid = '70px minmax(0, 1fr) 200px';
  const matchGrid = '180px minmax(0, 1fr) 90px 110px 160px 220px';

  container.innerHTML = `
    ${plainHead(TEAMS[id], `TEAM · REGION ${String(meta.region || '').toUpperCase()} · FOUNDED ${meta.founded} · CAPTAIN ${meta.captain.toUpperCase()}`, `TEAM #${id}`)}
    ${champions.length ? `
      <div class="rise rise-2 mono" style="display: flex; align-items: center; gap: 10px; margin-top: 22px; font-size: 11px; letter-spacing: 0.2em; color: var(--gold);">
        ${STAR(12)}CHAMPIONS · ${champions.join(' · ')}
      </div>` : ''}
    <div class="rise rise-2">
      <div class="stat-strip">
        <div class="stat"><div class="stat-label">RECORD</div><div class="stat-value mono">${wins}–${losses}</div></div>
        <div class="stat"><div class="stat-label">ROUNDS WON</div><div class="stat-value mono">${roundsWon}</div></div>
        <div class="stat"><div class="stat-label">PLAYERS</div><div class="stat-value mono">${rosterOf(id).length}</div></div>
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        ROSTER ${starRule()}
      </div>
      ${rosterOf(id).map((p) => `
        <div class="t-row" style="grid-template-columns: ${rosterGrid};">
          <div class="mono" style="font-size: 14px; color: var(--text-2);">${p.jersey}</div>
          <div style="font-weight: 700; font-size: 16px;"><a href="#/player/${p.id}" style="color: inherit;">${p.ign}</a></div>
          <div class="right mono" style="font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">${p.jersey <= 5 ? 'STARTER' : 'SUBSTITUTE'}</div>
        </div>`).join('')}
    </div>
    <div class="rise rise-3" style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        MATCH RECORD ${starRule()}
      </div>
      <div class="t-head" style="grid-template-columns: ${matchGrid}; margin-top: 20px;">
        <div>SESSION</div><div>OPPONENT</div><div class="right">RESULT</div><div class="right">SCORE</div><div class="right">TIME</div><div class="right">EVENT</div>
      </div>
      ${teamMatches.map((m) => {
        const lbl = matchLabel(m);
        const own = m.sides.find(([sideId]) => sideId === id);
        const opp = m.sides.find(([sideId]) => sideId !== id);
        const won = m.sides[0][0] === id;
        return `
          <a class="t-row" href="#/match/${m.id}" style="grid-template-columns: ${matchGrid};">
            <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
            <div style="font-weight: 700;">vs ${sideName(opp[0])}</div>
            <div class="right mono" style="font-size: 12px; font-weight: ${won ? 700 : 400}; color: ${won ? 'var(--gold)' : 'var(--text-3)'};">${won ? 'W' : 'L'}</div>
            <div class="right mono" style="font-size: 12px;">${own[1]}–${opp[1]}</div>
            <div class="right mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
            <div class="right" style="color: var(--text-2);">${tournament(m.t).name}</div>
          </a>`;
      }).join('')}
    </div>`;
}

export function renderPlayer(container, pid) {
  const id = Number(pid);
  const player = PLAYERS[id];
  if (!player) {
    container.innerHTML = plainHead('Player not found', '', '');
    return;
  }

  const [ign, teamId, jersey] = player;
  const head = plainHead(
    ign,
    teamId ? `PLAYER · ${TEAMS[teamId].toUpperCase()} · JERSEY #${jersey}` : 'PLAYER · SOLO COMPETITOR',
    `PLAYER #${id}`
  );

  if (teamId > 0) {
    const grid = '180px minmax(0, 1fr) 160px 90px 90px 90px 90px';
    const rows = MATCHES
      .filter((m) => m.stats && m.stats.some(([statPid]) => statPid === id))
      .sort((a, b) => a.id - b.id);
    const totals = rows.reduce((acc, m) => {
      const s = m.stats.find(([statPid]) => statPid === id);
      acc.k += s[1];
      acc.d += s[2];
      acc.a += s[3];
      return acc;
    }, { k: 0, d: 0, a: 0 });

    container.innerHTML = `
      ${head}
      <div class="rise rise-2">
        <div class="stat-strip">
          <div class="stat"><div class="stat-label">SESSIONS</div><div class="stat-value mono">${rows.length}</div></div>
          <div class="stat"><div class="stat-label">K</div><div class="stat-value mono">${totals.k}</div></div>
          <div class="stat"><div class="stat-label">D</div><div class="stat-value mono">${totals.d}</div></div>
          <div class="stat"><div class="stat-label">A</div><div class="stat-value mono">${totals.a}</div></div>
          <div class="stat"><div class="stat-label">K/D</div><div class="stat-value mono">${(totals.d ? totals.k / totals.d : 0).toFixed(2)}</div></div>
        </div>
      </div>
      ${rows.length ? `
        <div class="rise rise-3" style="margin-top: 36px;">
          <div class="t-head" style="grid-template-columns: ${grid};">
            <div>SESSION</div><div>EVENT</div><div>TIME</div>
            <div class="right">K</div><div class="right">D</div><div class="right">A</div><div class="right">SCORE</div>
          </div>
          ${rows.map((m) => {
            const s = m.stats.find(([statPid]) => statPid === id);
            const lbl = matchLabel(m);
            return `
              <a class="t-row" href="#/match/${m.id}" style="grid-template-columns: ${grid};">
                <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
                <div style="font-weight: 700;">${tournament(m.t).name}</div>
                <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
                <div class="num" style="font-weight: 700;">${s[1]}</div>
                <div class="num" style="color: var(--text-2);">${s[2]}</div>
                <div class="num" style="color: var(--text-2);">${s[3]}</div>
                <div class="num">${s[4]}</div>
              </a>`;
          }).join('')}
        </div>` : `
        <div class="rise rise-3 mono" style="margin-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">NO RECORDED SESSIONS</div>`}
    `;
    return;
  }

  if (id >= 47 && id <= 54) {
    const grid = '180px minmax(0, 1fr) 160px 120px 120px';
    const rows = MATCHES
      .filter((m) => m.lobby && m.lobby.some(([rowIgn]) => rowIgn === ign))
      .sort((a, b) => a.id - b.id)
      .map((m) => ({ match: m, row: m.lobby.find(([rowIgn]) => rowIgn === ign) }));
    const totalPoints = rows.reduce((sum, r) => sum + r.row[2], 0);
    const bestFinish = rows.length ? Math.min(...rows.map((r) => r.row[1])) : dash;

    container.innerHTML = `
      ${head}
      <div class="rise rise-2">
        <div class="stat-strip">
          <div class="stat"><div class="stat-label">LOBBIES</div><div class="stat-value mono">${rows.length}</div></div>
          <div class="stat"><div class="stat-label">TOTAL POINTS</div><div class="stat-value mono">${totalPoints}</div></div>
          <div class="stat"><div class="stat-label">BEST FINISH</div><div class="stat-value mono">${bestFinish}</div></div>
        </div>
      </div>
      ${rows.length ? `
        <div class="rise rise-3" style="margin-top: 36px;">
          <div class="t-head" style="grid-template-columns: ${grid};">
            <div>SESSION</div><div>EVENT</div><div>TIME</div><div class="right">PLACEMENT</div><div class="right">POINTS</div>
          </div>
          ${rows.map(({ match: m, row }) => {
            const lbl = matchLabel(m);
            return `
              <a class="t-row" href="#/match/${m.id}" style="grid-template-columns: ${grid};">
                <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
                <div style="font-weight: 700;">${tournament(m.t).name}</div>
                <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
                <div class="num" style="${row[1] === 1 ? 'font-weight: 700; color: var(--gold);' : 'color: var(--text-2);'}">${row[1]}</div>
                <div class="num-strong">${row[2]}</div>
              </a>`;
          }).join('')}
        </div>` : `
        <div class="rise rise-3 mono" style="margin-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">NO RECORDED SESSIONS</div>`}
    `;
    return;
  }

  if (id === 55 || id === 56) {
    const grid = '180px minmax(0, 1fr) 160px 120px 120px';
    const rows = MATCHES
      .filter((m) => m.solo && m.solo.some(([rowIgn]) => rowIgn === ign))
      .sort((a, b) => a.id - b.id);
    const wins = rows.filter((m) => m.solo[0][0] === ign).length;

    container.innerHTML = `
      ${head}
      <div class="rise rise-2">
        <div class="stat-strip">
          <div class="stat"><div class="stat-label">GAMES</div><div class="stat-value mono">${rows.length}</div></div>
          <div class="stat"><div class="stat-label">WINS</div><div class="stat-value mono">${wins}</div></div>
        </div>
      </div>
      ${rows.length ? `
        <div class="rise rise-3" style="margin-top: 36px;">
          <div class="t-head" style="grid-template-columns: ${grid};">
            <div>SESSION</div><div>EVENT</div><div>TIME</div><div class="right">RESULT</div><div class="right">SCORE</div>
          </div>
          ${rows.map((m) => {
            const lbl = matchLabel(m);
            const idx = m.solo[0][0] === ign ? 0 : 1;
            const opp = idx === 0 ? 1 : 0;
            const won = idx === 0;
            return `
              <a class="t-row" href="#/match/${m.id}" style="grid-template-columns: ${grid};">
                <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
                <div style="font-weight: 700;">${tournament(m.t).name}</div>
                <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
                <div class="right mono" style="font-size: 12px; font-weight: ${won ? 700 : 400}; color: ${won ? 'var(--gold)' : 'var(--text-3)'};">${won ? 'W' : 'L'}</div>
                <div class="right mono" style="font-size: 12px;">${m.solo[idx][1]}–${m.solo[opp][1]}</div>
              </a>`;
          }).join('')}
        </div>` : `
        <div class="rise rise-3 mono" style="margin-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">NO RECORDED SESSIONS</div>`}
    `;
    return;
  }

  container.innerHTML = `
    ${head}
    <div class="rise rise-2 mono" style="margin-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">NO RECORDED SESSIONS</div>`;
}

export function renderProfile(container) {
  const p = PORTAL.player;
  const stats = [
    ['TEAM', p.team, ''],
    ['JERSEY', `#${p.jersey}`, ''],
    ['COUNTRY', p.country, ''],
    ['BORN', p.born, ''],
    ['JOINED', p.joined, ''],
    ['SALARY / MO', p.salary, 'HIDDEN FROM PUBLIC ROSTERS'],
  ];

  container.innerHTML = `
    ${plainHead('My Profile', 'V_MY_PROFILE · VISIBLE ONLY TO YOU', 'PLAYER · AUS#MTB')}
    <div class="rise rise-2">
      <div class="stat-strip">
        ${stats.map(([label, value, note]) => `
          <div class="stat">
            <div class="stat-label">${label}</div>
            <div class="stat-value ${label === 'SALARY / MO' ? 'gold' : ''}">${value}</div>
            ${note ? `<div class="stat-label">${note}</div>` : ''}
          </div>`).join('')}
      </div>
      <div class="mono" style="margin-top: 34px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">
        THE PUBLIC ROSTER SHOWS THIS ROW WITHOUT THE SALARY COLUMN · THAT IS THE ROW-LEVEL SECURITY DEMO FROM THE DATABASE
      </div>
    </div>`;
}

export function renderHistory(container) {
  const grid = '180px minmax(0, 1fr) 160px 90px 90px 90px 90px';
  const rows = MATCHES
    .filter((m) => m.stats && m.stats.some(([pid]) => pid === 1))
    .sort((a, b) => a.id - b.id);

  container.innerHTML = `
    ${plainHead('Match History', 'V_MY_MATCH_HISTORY · AUS#MTB · PER-SESSION STATS', 'PLAYER · AUS#MTB')}
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>SESSION</div><div>EVENT</div><div>TIME</div>
        <div class="right">K</div><div class="right">D</div><div class="right">A</div><div class="right">SCORE</div>
      </div>
      ${rows.map((m) => {
        const s = m.stats.find(([pid]) => pid === 1);
        const lbl = matchLabel(m);
        return `
          <a class="t-row" href="#/match/${m.id}" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 12px; color: var(--text-3);">${lbl.long}</div>
            <div style="font-weight: 700;">${tournament(m.t).name}</div>
            <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
            <div class="num" style="font-weight: 700;">${s[1]}</div>
            <div class="num" style="color: var(--text-2);">${s[2]}</div>
            <div class="num" style="color: var(--text-2);">${s[3]}</div>
            <div class="num">${s[4]}</div>
          </a>`;
      }).join('')}
    </div>`;
}

export function renderOrgPayouts(container) {
  const grid = 'minmax(0, 1fr) 240px 110px 190px 140px';

  container.innerHTML = `
    ${plainHead('Team Payouts', 'V_MY_TEAM_PAYOUTS · QOR · YOUR TEAMS ONLY', 'ORG · QOR')}
    <div class="rise rise-2">
      <div class="stat-strip">
        <div class="stat"><div class="stat-label">TEAMS</div><div class="stat-value">2</div></div>
        <div class="stat"><div class="stat-label">RECEIVED</div><div class="stat-value">500</div></div>
        <div class="stat"><div class="stat-label">PENDING</div><div class="stat-value">1,000</div></div>
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>TEAM</div><div>EVENT</div><div class="right">AMOUNT</div><div>STATUS</div><div class="right">DATE</div>
      </div>
      ${PORTAL.org.payouts.map(([team, event, amount, status, date]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${team}</div>
          <div style="color: var(--text-2);">${event}</div>
          <div class="num">${amount}</div>
          <div>${status === 'NO PAYOUT RECORDED' ? `<span class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--text-3);">${status}</span>` : statusPill(status)}</div>
          <div class="num">${date}</div>
        </div>`).join('')}
    </div>`;
}

let opsEventFilter = 'all';
let opsStreamInput = '';
let opsStreamTouched = false;
let opsNotice = null;
let opsFocusId = null;
let opsFocusSelection = null;

function opsCapture(container) {
  if (!container) return;
  const active = document.activeElement;
  const input = container.querySelector('#ops-stream');
  if (input) opsStreamInput = input.value;
  if (active && container.contains(active) && active.id) {
    opsFocusId = active.id;
    if (typeof active.selectionStart === 'number') {
      opsFocusSelection = { start: active.selectionStart, end: active.selectionEnd };
    } else {
      opsFocusSelection = null;
    }
  }
}

function opsRefocus(container) {
  if (!opsFocusId) return;
  const target = container.querySelector(`#${opsFocusId}`);
  if (!target) return;
  target.focus();
  if (opsFocusSelection && typeof target.setSelectionRange === 'function') {
    target.setSelectionRange(opsFocusSelection.start, opsFocusSelection.end);
  }
}

function opsStatusChip(status) {
  const clean = String(status || '').toLowerCase();
  if (clean === 'live') return '<span class="chip chip-live">LIVE</span>';
  if (clean === 'completed') return '<span class="chip chip-done">COMPLETED</span>';
  return '<span class="chip" style="color: var(--text-2);">UPCOMING</span>';
}

function opsCompetitors(m) {
  if (m.sides) return { text: `${sideName(m.sides[0][0])} vs ${sideName(m.sides[1][0])}`, played: true };
  if (m.lobby) return { text: '8 player lobby', played: true };
  if (m.solo) return { text: `${String(sideName(m.solo[0][0])).replace(/#[A-Za-z0-9]+$/, '')} vs ${String(sideName(m.solo[1][0])).replace(/#[A-Za-z0-9]+$/, '')}`, played: true };
  return { text: m.hint || 'TBD vs TBD', played: false };
}

function opsState(m) {
  return m.sides || m.lobby || m.solo
    ? '<span class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--text-3);">RECORDED</span>'
    : '<span class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--text-2);">UPCOMING</span>';
}

function opsWire(container) {
  container.querySelectorAll('[data-ops-filter]').forEach((chip) => {
    chip.onclick = () => {
      opsCapture(container);
      opsEventFilter = chip.dataset.opsFilter || 'all';
      opsStreamInput = '';
      opsStreamTouched = false;
      opsFocusId = null;
      opsFocusSelection = null;
      renderOps(container);
    };
  });

  const input = container.querySelector('#ops-stream');
  if (input) {
    input.oninput = () => {
      opsStreamTouched = true;
      opsCapture(container);
      renderOps(container);
    };
  }

  const save = container.querySelector('[data-ops-stream-save]');
  if (save) {
    save.onclick = () => {
      opsCapture(container);
      const code = save.dataset.opsStreamSave;
      const result = setStream(code, opsStreamInput);
      if (result.ok) {
        opsStreamInput = result.channel;
        opsStreamTouched = false;
        opsNotice = { kind: 'ok', text: result.channel ? `STREAM SET &middot; twitch.tv/${esc(result.channel)}` : 'STREAM CLEARED' };
      } else {
        opsNotice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      }
      renderOps(container);
    };
  }
}

export function renderOps(container) {
  const shownNotice = opsNotice;
  opsNotice = null;
  const grid = '180px minmax(0, 1fr) 150px 240px 130px 120px';
  const eventOptions = TOURNAMENTS.filter((t) => matchesFor(t.code).length);
  if (opsEventFilter !== 'all' && !eventOptions.some((t) => t.code === opsEventFilter)) opsEventFilter = 'all';
  const selectedEvent = opsEventFilter === 'all' ? null : eventOptions.find((t) => t.code === opsEventFilter);
  const sections = eventOptions.filter((t) => opsEventFilter === 'all' || t.code === opsEventFilter);
  const activeStream = selectedEvent ? streamFor(selectedEvent.code) : '';
  const streamValue = selectedEvent && !opsStreamTouched && !opsStreamInput ? activeStream : opsStreamInput;

  container.innerHTML = `
    ${plainHead('Run Sheet', 'V_TOURNAMENT_OPS &middot; SESSIONS BY EVENT &middot; STAFF AND STREAM COVERAGE', 'STAFF &middot; HEAD CASTER')}
    ${shownNotice ? `<div class="confirm" style="${shownNotice.kind === 'err' ? 'color: var(--loser);' : ''}">${shownNotice.kind === 'ok' ? STAR(11) : ''}${shownNotice.text}</div>` : ''}
    <div class="chips rise rise-2" style="margin-top: 28px;">
      <button class="${opsEventFilter === 'all' ? 'chip-btn sel' : 'chip-btn'}" type="button" data-ops-filter="all">ALL</button>
      ${eventOptions.map((t) => `
        <button class="${opsEventFilter === t.code ? 'chip-btn sel' : 'chip-btn'}" type="button" data-ops-filter="${esc(t.code)}">${esc(t.name)}</button>`).join('')}
    </div>
    ${selectedEvent ? `
      <div class="rise rise-3" style="margin-top: 34px;">
        <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
          BROADCAST ${starRule()}
        </div>
        <div class="form-row">
          <label class="field">
            <span class="field-label">TWITCH STREAM</span>
            <input id="ops-stream" class="input" type="text" placeholder="TWITCH CHANNEL OR URL" value="${esc(streamValue)}">
          </label>
          <button class="btn-gold" type="button" data-ops-stream-save="${esc(selectedEvent.code)}">SET STREAM</button>
        </div>
        ${activeStream ? `
          <div class="stream-frame">
            <iframe src="https://player.twitch.tv/?channel=${esc(activeStream)}&parent=localhost&muted=true" allowfullscreen></iframe>
          </div>
          <div class="mono" style="font-size: 10px; color: var(--text-3); margin-top: 8px;">EMBED REQUIRES INTERNET &middot; twitch.tv/${esc(activeStream)}</div>` : ''}
      </div>` : ''}
    ${sections.map((t, sectionIndex) => {
      const rows = matchesFor(t.code);
      return `
        <div class="rise rise-${Math.min(sectionIndex + 3, 4)}" style="margin-top: 38px;">
          <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
            ${glyph(t.glyph, 28)}
            <span>${esc(t.name.toUpperCase())}</span>
            ${opsStatusChip(t.status)}
            <span class="mono" style="color: var(--text-3);">${esc(t.dates)}</span>
            ${starRule()}
          </div>
          <div class="t-head" style="grid-template-columns: ${grid}; margin-top: 18px;">
            <div>SESSION</div><div>COMPETITORS</div><div>TIME</div><div>STAFF</div><div>CREATORS</div><div>STATE</div>
          </div>
          ${rows.map((m) => {
            const lbl = matchLabel(m);
            const ops = OPS[m.id] || {};
            const competitors = opsCompetitors(m);
            const staff = ops.staff && ops.staff.length
              ? esc(ops.staff.join(', '))
              : competitors.played
                ? dash
                : '<span class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--gold);">NO STAFF ASSIGNED</span>';
            const creators = ops.creators && ops.creators.length ? esc(ops.creators.join(', ')) : dash;
            return `
              <div class="t-row" style="grid-template-columns: ${grid};">
                <div class="mono" style="font-size: 12px; color: var(--text-3);">${esc(lbl.long)}</div>
                <div style="${competitors.played ? 'font-weight: 700;' : 'color: var(--text-2);'}">${esc(competitors.text)}</div>
                <div class="mono" style="font-size: 12px; color: var(--text-2);">${esc(m.time)}</div>
                <div style="color: var(--text-2);">${staff}</div>
                <div style="color: var(--text-2);">${creators}</div>
                <div>${opsState(m)}</div>
              </div>`;
          }).join('')}
        </div>`;
    }).join('')}`;

  opsWire(container);
  opsRefocus(container);
}

export function renderDeliverables(container) {
  const grid = '170px 210px minmax(0, 1fr) 120px 130px 130px 90px';

  container.innerHTML = `
    ${plainHead('Deliverables', 'V_DELIVERABLE_STATUS · SPONSOR AND CREATOR OBLIGATIONS', 'STAFF · HEAD CASTER')}
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>PARTY</div><div>EVENT</div><div>DESCRIPTION</div><div>TYPE</div><div>DUE</div><div>STATUS</div><div class="right">CLICKS</div>
      </div>
      ${DELIVERABLES.map(([party, , event, description, type, due, status, clicks]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${party}</div>
          <div style="color: var(--text-2);">${event}</div>
          <div>${description}</div>
          <div class="mono" style="font-size: 12px; color: var(--text-2);">${type}</div>
          <div class="mono" style="font-size: 12px;">${due}</div>
          <div>${statusPill(status)}</div>
          <div class="num">${clicks === 0 ? dash : clicks}</div>
        </div>`).join('')}
    </div>`;
}

export function renderIntegrity(container) {
  const grid = '180px minmax(0, 1fr) 160px 320px';

  container.innerHTML = `
    ${plainHead('Data Quality', 'V_REGISTRATION_VIOLATIONS · V_MATCH_INTEGRITY', 'STAFF · HEAD CASTER')}
    <div class="rise rise-2" style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        REGISTRATION VIOLATIONS ${starRule()}
      </div>
      <div class="mono" style="display: flex; align-items: center; gap: 10px; padding: 22px 0; font-size: 12px; color: var(--text-2);">
        ${STAR(12)}NO VIOLATIONS · EVERY REGISTERED TEAM PLAYS ITS TOURNAMENT'S GAME
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 32px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        MATCH INTEGRITY ${starRule()}
      </div>
      <div class="t-head" style="grid-template-columns: ${grid}; margin-top: 20px;">
        <div>SESSION</div><div>EVENT</div><div>TIME</div><div>ISSUE</div>
      </div>
      ${INTEGRITY.matchIssues.map(([session, event, time, issue]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 12px; color: var(--text-3);">${session}</div>
          <div style="font-weight: 700;">${event}</div>
          <div class="mono" style="font-size: 12px; color: var(--text-2);">${time}</div>
          <div class="mono" style="font-size: 11px; color: var(--gold);">${issue}</div>
        </div>`).join('')}
      <div class="mono" style="padding-top: 20px; font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">
        ${INTEGRITY.cleanMatches} OTHER SESSIONS · OK · EXPECTED FOR LIVE AND UPCOMING SESSIONS
      </div>
    </div>`;
}

export function renderSponsor(container) {
  const c = PORTAL.sponsor.contract;
  const grid = 'minmax(0, 1fr) 140px 140px 140px 100px';

  container.innerHTML = `
    ${plainHead('Sponsor Portal', 'V_MY_CONTRACT_DELIVERABLES · RED BULL · YOUR CONTRACT ONLY', 'SPONSOR · RED BULL')}
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="tile" style="max-width: 560px;">
        <div class="section-label">ACTIVE CONTRACT</div>
        <div class="tile-name">${c.event}</div>
        <div class="mono" style="font-size: 11px; color: var(--text-2);">${c.window}</div>
        <div class="stat">
          <div class="stat-value gold" style="font-size: 22px;">${c.value}</div>
          <div class="stat-label">TOTAL VALUE</div>
        </div>
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>DESCRIPTION</div><div>TYPE</div><div>DUE</div><div>STATUS</div><div class="right">CLICKS</div>
      </div>
      ${PORTAL.sponsor.deliverables.map(([description, type, due, status, clicks]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${description}</div>
          <div class="mono" style="font-size: 12px; color: var(--text-2);">${type}</div>
          <div class="mono" style="font-size: 12px;">${due}</div>
          <div>${statusPill(status)}</div>
          <div class="num">${clicks}</div>
        </div>`).join('')}
    </div>`;
}

export function renderCreator(container) {
  const grid = 'minmax(0, 1fr) 160px 110px 140px 190px';
  const creator = CREATORS.find((entry) => entry.id === 1);
  const links = creator ? [
    [platIcon('tw'), creator.twitch],
    [platIcon('ig'), creator.instagram],
    [platIcon('x'), creator.twitter],
  ].filter(([, value]) => value) : [];
  const linkLine = links.length
    ? links.map(([label, value]) => `<span><span class="plat">${label}</span> ${esc(value)}</span>`).join('')
    : dash;
  const assignments = CREATOR_ASSIGNMENTS.filter((assignment) => assignment.creatorId === 1);

  container.innerHTML = `
    ${plainHead('Creator Portal', `V_MY_CREATOR_ASSIGNMENTS · ${esc(creator ? creator.name.toUpperCase() : 'CREATOR')} · YOUR ASSIGNMENTS ONLY`, `CREATOR · ${esc(creator ? creator.name.toUpperCase() : 'REVRZD')}`)}
    <div class="rise rise-2" style="margin-top: 34px;">
      <div class="link-line" style="color: var(--gold);">${linkLine}</div>
    </div>
    <div class="rise rise-3" style="margin-top: 28px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>EVENT</div><div>ROLE</div><div class="right">RATE</div><div>STATUS</div><div class="right">MATCHES STREAMED</div>
      </div>
      ${assignments.map((assignment) => {
        const event = tournament(assignment.code);
        const streamed = assignment.code === 'CC' || assignment.code === 'SS' ? 2 : dash;
        return `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${esc(event ? event.name : 'Unknown event')}</div>
          <div class="mono" style="font-size: 12px;">${esc(assignment.role)}</div>
          <div class="num">${esc(assignment.rate)}</div>
          <div>${statusPill(assignment.status)}</div>
          <div class="num">${streamed}</div>
        </div>`;
      }).join('')}
    </div>`;
}
