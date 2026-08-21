// Star Tournaments · role and utility pages.

import {
  TEAMS,
  PLAYERS,
  MATCHES,
  DELIVERABLES,
  INTEGRITY,
  OPS,
  PORTAL,
  rosterOf,
  tournament,
  matchesFor,
} from './data.js';
import { STAR, starRule, plainHead } from './ui-kit.js';

const dash = '–';

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

export function renderRosters(container) {
  const grid = '70px minmax(0, 1fr) 200px';
  const sections = Object.keys(TEAMS).map((teamId) => `
    <div style="margin-top: 38px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        ${TEAMS[teamId].toUpperCase()} ${starRule()}
      </div>
      ${rosterOf(Number(teamId)).map((p) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 14px; color: var(--text-2);">${p.jersey}</div>
          <div style="font-weight: 700; font-size: 16px;">${p.ign}</div>
          <div class="right mono" style="font-size: 10px; letter-spacing: 0.2em; color: var(--text-3);">${p.jersey <= 5 ? 'STARTER' : 'SUBSTITUTE'}</div>
        </div>`).join('')}
    </div>`).join('');

  container.innerHTML = `
    ${plainHead('Rosters', 'V_PUBLIC_ROSTERS · ACTIVE LINEUPS · SALARIES HIDDEN FROM PUBLIC VIEW', 'AUDIENCE')}
    <div class="rise rise-2">${sections}</div>`;
}

export function renderPlayers(container) {
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
    ${plainHead('Player Leaderboard', 'V_PUBLIC_PLAYER_STATS · VALORANT · ALL SESSIONS', 'AUDIENCE')}
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
            <div style="font-weight: 700; font-size: 16px;">${p[0]}</div>
            <div style="color: var(--text-2);">${TEAMS[p[1]]}</div>
            <div class="num">${r.matches}</div>
            <div class="num">${r.kills}</div>
            <div class="num">${r.deaths}</div>
            <div class="num">${r.assists}</div>
            <div class="num">${(r.deaths ? r.kills / r.deaths : 0).toFixed(2)}</div>
          </div>`;
      }).join('')}
    </div>`;
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
  const grid = '110px minmax(0, 1fr) 160px 90px 90px 90px 90px';
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
            <div class="mono" style="font-size: 12px; color: var(--text-3);">${m.t}-${lbl.short}</div>
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

export function renderOps(container) {
  const grid = '100px 220px 150px minmax(0, 1fr) 260px 110px';
  const competitors = (m) => {
    if (m.sides) return `${sideName(m.sides[0][0])} vs ${sideName(m.sides[1][0])}`;
    if (m.solo) return `${sideName(m.solo[0][0])} vs ${sideName(m.solo[1][0])}`;
    if (m.lobby) return '8 player lobby';
    return m.hint || 'TBD vs TBD';
  };

  container.innerHTML = `
    ${plainHead('Run Sheet', 'V_TOURNAMENT_OPS · EVERY SESSION · STAFF AND STREAM COVERAGE', 'STAFF · HEAD CASTER')}
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>SESSION</div><div>EVENT</div><div>TIME</div><div>COMPETITORS</div><div>STAFF</div><div class="right">CREATORS</div>
      </div>
      ${[...MATCHES].sort((a, b) => a.id - b.id).map((m) => {
        const lbl = matchLabel(m);
        const ops = OPS[m.id] || {};
        return `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 12px; color: var(--text-3);">${m.t}-${lbl.short}</div>
            <div style="font-weight: 700;">${tournament(m.t).name}</div>
            <div class="mono" style="font-size: 12px; color: var(--text-2);">${m.time}</div>
            <div>${competitors(m)}</div>
            <div style="color: var(--text-2);">${ops.staff ? ops.staff.join(', ') : dash}</div>
            <div class="right" style="color: var(--text-2);">${ops.creators ? ops.creators.join(', ') : dash}</div>
          </div>`;
      }).join('')}
    </div>`;
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
  const grid = '110px minmax(0, 1fr) 160px 320px';

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

  container.innerHTML = `
    ${plainHead('Creator Portal', 'V_MY_CREATOR_ASSIGNMENTS · REVRZD · YOUR ASSIGNMENTS ONLY', 'CREATOR · REVRZD')}
    <div class="rise rise-2" style="margin-top: 34px;">
      <div class="mono" style="font-size: 11px; letter-spacing: 0.18em; color: var(--gold);">${PORTAL.creator.link}</div>
    </div>
    <div class="rise rise-3" style="margin-top: 28px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>EVENT</div><div>ROLE</div><div class="right">RATE</div><div>STATUS</div><div class="right">MATCHES STREAMED</div>
      </div>
      ${PORTAL.creator.assignments.map(([event, role, rate, status, streamed]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${event}</div>
          <div class="mono" style="font-size: 12px;">${role}</div>
          <div class="num">${rate}</div>
          <div>${statusPill(status)}</div>
          <div class="num">${streamed}</div>
        </div>`).join('')}
    </div>`;
}
