// Star Tournaments event-day check-in desk.

import {
  TOURNAMENTS,
  TEAMS,
  TEAM_META,
  rosterOf,
  playerCheckinsFor,
  playerCheckIn,
  undoPlayerCheckIn,
  checkInTeam,
  undoTeam,
} from './data.js';
import { STAR, glyph, starRule, plainHead } from './ui-kit.js';

let selectedCode = null;
let expanded = new Set();
let notice = null;

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function eligibleEvents() {
  return TOURNAMENTS.filter((event) =>
    event.format === 'elim' &&
    Array.isArray(event.field) &&
    (event.status === 'live' || event.status === 'upcoming')
  );
}

function defaultEvent(events) {
  return events.find((event) => event.status === 'live') ||
    events.find((event) => event.status === 'upcoming') ||
    events[0];
}

function eventStatus(event) {
  if (event.status === 'live') return '<span class="chip chip-live">LIVE</span>';
  return '<span class="chip" style="color: var(--text-2);">UPCOMING</span>';
}

function eventSelector(events, selected) {
  return `
    <div class="rise rise-2" style="margin-top: 30px;">
      <div class="chips" style="align-items: center;">
        ${events.map((event) => `
          <button
            class="chip-btn ${event.code === selected.code ? 'sel' : ''}"
            type="button"
            data-event="${esc(event.code)}"
            title="${esc(event.name)}"
          >${esc(event.name)}</button>
        `).join('')}
        <span class="mono" style="font-size: 10px; color: var(--text-2); letter-spacing: 0.16em;">
          ${esc(selected.name)} &middot; ${eventStatus(selected)} &middot; ${esc(selected.dates)}
        </span>
      </div>
    </div>`;
}

function teamState(teamId, eventCheckins) {
  const roster = rosterOf(teamId);
  const starters = roster.filter((player) => player.jersey <= 5);
  const playersChecked = roster.filter((player) => eventCheckins[String(player.id)]).length;
  const ready = starters.length === 5 && starters.every((player) => eventCheckins[String(player.id)]);
  return { roster, starters, playersChecked, ready };
}

function eventState(event, eventCheckins) {
  const teams = event.field.map((teamId) => ({
    id: Number(teamId),
    ...teamState(teamId, eventCheckins),
  }));
  const playersRegistered = teams.reduce((sum, team) => sum + team.roster.length, 0);
  const checkedIn = teams.reduce((sum, team) => sum + team.playersChecked, 0);
  const readyCount = teams.filter((team) => team.ready).length;
  return { teams, playersRegistered, checkedIn, readyCount };
}

function statStrip(summary) {
  const allReady = summary.teams.length > 0 && summary.readyCount === summary.teams.length;
  return `
    <div class="stat-strip rise rise-2">
      <div class="stat">
        <div class="stat-label">PLAYERS REGISTERED</div>
        <div class="stat-value mono">${summary.playersRegistered}</div>
      </div>
      <div class="stat">
        <div class="stat-label">CHECKED IN</div>
        <div class="stat-value mono">${summary.checkedIn}</div>
      </div>
      <div class="stat">
        <div class="stat-label">TEAMS READY</div>
        <div class="stat-value mono" style="${allReady ? 'color: var(--gold);' : ''}">${summary.readyCount}/${summary.teams.length}</div>
      </div>
    </div>`;
}

function chevron(open) {
  return `
    <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true" style="transform: rotate(${open ? 90 : 0}deg); transform-origin: center;">
      <path d="M6 3 L11 8 L6 13" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"></path>
    </svg>`;
}

function teamRow(team, index) {
  const meta = TEAM_META[team.id];
  const total = team.roster.length;
  const open = expanded.has(team.id);
  const allPlayersIn = team.playersChecked === total;
  const progress = `
    <div class="mono" style="font-size: 11px; letter-spacing: 0.16em;">
      <div>${team.playersChecked}/${total} PLAYERS</div>
      ${team.ready
        ? `<div style="display: flex; align-items: center; gap: 7px; color: var(--gold); margin-top: 5px;">${STAR(10)}READY</div>`
        : '<div class="text-3" style="color: var(--text-3); margin-top: 5px;">WAITING</div>'}
    </div>`;
  const action = allPlayersIn
    ? `<button class="btn-quiet" type="button" data-team-undo="${team.id}">UNDO ALL</button>`
    : `<button class="btn-quiet" type="button" data-team-all="${team.id}">CHECK IN ALL</button>`;

  return `
    <div class="t-row clickable" data-team-row="${team.id}" style="grid-template-columns: 44px 56px minmax(0, 1fr) 240px 240px;">
      <div style="color: var(--text-3); display: flex; align-items: center;">${chevron(open)}</div>
      <div class="mono" style="font-size: 12px; color: var(--text-3);">S${index + 1}</div>
      <div>
        <a href="#/team/${team.id}" style="color: inherit; font-weight: 700; font-size: 17px;">${esc(TEAMS[team.id])}</a>
        <div class="mono" style="font-size: 12px; color: var(--text-2); margin-top: 5px;">CAPTAIN ${meta ? esc(meta.captain) : '&#8211;'}</div>
      </div>
      <div>${progress}</div>
      <div class="right">${action}</div>
    </div>`;
}

function playerRow(player, eventCheckins) {
  const time = eventCheckins[String(player.id)];
  const starter = player.jersey <= 5;
  const status = time
    ? `<div class="mono" style="display: flex; align-items: center; gap: 7px; font-size: 11px; letter-spacing: 0.16em; color: var(--gold);">${STAR(9)}IN &middot; ${esc(time)}</div>`
    : '<div class="mono text-3" style="font-size: 11px; letter-spacing: 0.16em; color: var(--text-3);">NOT CHECKED IN</div>';
  const action = time
    ? `<button class="btn-quiet" type="button" data-player-undo="${player.id}" style="padding: 8px 14px; font-size: 10px;">UNDO</button>`
    : `<button class="btn-gold" type="button" data-player="${player.id}" style="padding: 8px 14px; font-size: 10px;">CHECK IN</button>`;

  return `
    <div style="display: grid; grid-template-columns: 100px 90px minmax(0, 1fr) 220px 200px; align-items: center; padding: 10px 0; border-bottom: 1px solid var(--line); background: var(--surface);">
      <div></div>
      <div class="mono" style="font-size: 12px; color: var(--text-2);">#${player.jersey}</div>
      <div style="display: flex; align-items: center; gap: 10px; min-width: 0;">
        <a href="#/player/${player.id}" style="color: inherit; font-weight: 700; font-size: 15px; min-width: 0; overflow-wrap: anywhere;">${esc(player.ign)}</a>
        <span class="mono text-3" style="font-size: 9px; color: var(--text-3); letter-spacing: 0.16em; white-space: nowrap;">${starter ? 'STARTER' : 'SUBSTITUTE'}</span>
      </div>
      <div>${status}</div>
      <div class="right">${action}</div>
    </div>`;
}

function teamBlock(team, index, eventCheckins) {
  return `
    ${teamRow(team, index)}
    ${expanded.has(team.id) ? team.roster.map((player) => playerRow(player, eventCheckins)).join('') : ''}`;
}

function checkinTable(event, summary, eventCheckins) {
  const allReady = summary.teams.length > 0 && summary.readyCount === summary.teams.length;

  return `
    <div class="rise rise-3" style="margin-top: 40px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        ${glyph(event.glyph, 28)}
        <span>${esc(event.name.toUpperCase())}</span>
        ${starRule()}
      </div>
      <div class="t-head" style="grid-template-columns: 44px 56px minmax(0, 1fr) 240px 240px; margin-top: 20px;">
        <div></div><div>SEED</div><div>TEAM</div><div>PROGRESS</div><div class="right">ACTION</div>
      </div>
      ${summary.teams.map((team, index) => teamBlock(team, index, eventCheckins)).join('')}
      ${allReady ? `<div class="confirm">${STAR(11)}ALL COMPETITORS CHECKED IN &middot; READY FOR MATCH START</div>` : ''}
    </div>`;
}

function wire(container, selected) {
  container.querySelectorAll('[data-event]').forEach((chip) => {
    chip.onclick = () => {
      if (selectedCode !== chip.dataset.event) expanded.clear();
      selectedCode = chip.dataset.event;
      renderCheckin(container);
    };
  });

  container.querySelectorAll('[data-team-row]').forEach((row) => {
    row.onclick = (event) => {
      if (event.target.closest && event.target.closest('a, button')) return;
      const teamId = Number(row.dataset.teamRow);
      if (expanded.has(teamId)) expanded.delete(teamId);
      else expanded.add(teamId);
      renderCheckin(container);
    };
  });

  container.querySelectorAll('[data-team-all]').forEach((button) => {
    button.onclick = () => {
      const result = checkInTeam(selected.code, button.dataset.teamAll);
      if (!result.ok) notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      renderCheckin(container);
    };
  });

  container.querySelectorAll('[data-team-undo]').forEach((button) => {
    button.onclick = () => {
      const result = undoTeam(selected.code, button.dataset.teamUndo);
      if (!result.ok) notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      renderCheckin(container);
    };
  });

  container.querySelectorAll('[data-player]').forEach((button) => {
    button.onclick = () => {
      const result = playerCheckIn(selected.code, button.dataset.player);
      if (!result.ok) notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      renderCheckin(container);
    };
  });

  container.querySelectorAll('[data-player-undo]').forEach((button) => {
    button.onclick = () => {
      const result = undoPlayerCheckIn(selected.code, button.dataset.playerUndo);
      if (!result.ok) notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      renderCheckin(container);
    };
  });
}

export function renderCheckin(container) {
  const shownNotice = notice;
  notice = null;
  const events = eligibleEvents();

  if (!events.length) {
    container.innerHTML = `
      ${plainHead('Check-In', 'EVENT DAY DESK &middot; REGISTERED COMPETITORS ONLY', 'STAFF &middot; HEAD CASTER')}
      <div class="rise rise-2 mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em; margin-top: 28px;">
        NO OPEN EVENTS &middot; CHECK-IN OPENS WHEN AN EVENT IS LIVE OR UPCOMING
      </div>`;
    return;
  }

  const selected = events.find((event) => event.code === selectedCode) || defaultEvent(events);
  if (selectedCode !== selected.code) {
    selectedCode = selected.code;
    expanded.clear();
  }

  const eventCheckins = playerCheckinsFor(selected.code);
  const summary = eventState(selected, eventCheckins);

  container.innerHTML = `
    ${plainHead('Check-In', 'EVENT DAY DESK &middot; REGISTERED COMPETITORS ONLY', 'STAFF &middot; HEAD CASTER')}
    ${shownNotice ? `<div class="confirm" style="${shownNotice.kind === 'err' ? 'color: var(--loser);' : ''}">${shownNotice.kind === 'ok' ? STAR(11) : ''}${shownNotice.text}</div>` : ''}
    ${eventSelector(events, selected)}
    ${statStrip(summary)}
    ${checkinTable(selected, summary, eventCheckins)}`;
  wire(container, selected);
}
