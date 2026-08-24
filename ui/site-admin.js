// Site Editor admin page.

import {
  TOURNAMENTS,
  MATCHES,
  TEAMS,
  TEAM_META,
  PLAYERS,
  saveEventEdit,
  saveMatchTime,
  saveTeamEdit,
  savePlayerEdit,
  tournament,
  matchesFor,
} from './data.js';
import { STAR, plainHead, starRule } from './ui-kit.js';

const state = {
  tab: 'EVENTS',
  eventCode: TOURNAMENTS[0] ? TOURNAMENTS[0].code : null,
  teamId: Number(Object.keys(TEAMS)[0] || 1),
  playerId: null,
  playerSearch: '',
  eventEditor: null,
  teamEditor: null,
  playerEditor: null,
  timeEdits: {},
  notice: null,
  focusId: null,
};

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

function competitors(m) {
  if (m.sides) return `${sideName(m.sides[0][0])} vs ${sideName(m.sides[1][0])}`;
  if (m.solo) return `${sideName(m.solo[0][0])} vs ${sideName(m.solo[1][0])}`;
  if (m.lobby) return '8 player lobby';
  return m.hint || 'TBD vs TBD';
}

function fillEventEditor(event) {
  state.eventCode = event ? event.code : null;
  state.eventEditor = event ? {
    name: event.name || '',
    prize: event.prize || '',
    dates: event.dates || '',
    note: event.note || '',
    championMeta: event.championMeta || '',
    championPrize: event.championPrize || '',
  } : {};
  state.timeEdits = {};
  if (event) {
    matchesFor(event.code).forEach((m) => {
      state.timeEdits[String(m.id)] = m.time || '';
    });
  }
}

function fillTeamEditor(teamId) {
  const id = Number(teamId);
  const meta = TEAM_META[id] || {};
  state.teamId = id;
  state.teamEditor = {
    name: TEAMS[id] || '',
    captain: meta.captain || '',
    founded: meta.founded || '',
    region: meta.region || '',
  };
}

function fillPlayerEditor(pid) {
  const id = Number(pid);
  const player = PLAYERS[id];
  state.playerId = player ? id : null;
  state.playerEditor = player ? {
    ign: player[0] || '',
    jersey: String(player[2] || ''),
  } : null;
}

function ensureEditors() {
  const event = TOURNAMENTS.find((t) => t.code === state.eventCode) || TOURNAMENTS[0];
  if (!event || state.eventEditor === null || event.code !== state.eventCode) fillEventEditor(event);
  const teamMissing = !TEAMS[state.teamId];
  if (teamMissing) state.teamId = Number(Object.keys(TEAMS)[0] || 1);
  if (state.teamEditor === null || teamMissing) fillTeamEditor(state.teamId);
}

function capture(container) {
  if (!container) return;
  container.querySelectorAll('[data-event-field]').forEach((input) => {
    if (state.eventEditor === null) state.eventEditor = {};
    state.eventEditor[input.dataset.eventField] = input.value;
  });
  container.querySelectorAll('[data-team-field]').forEach((input) => {
    if (state.teamEditor === null) state.teamEditor = {};
    state.teamEditor[input.dataset.teamField] = input.value;
  });
  container.querySelectorAll('[data-player-field]').forEach((input) => {
    if (state.playerEditor === null) state.playerEditor = {};
    state.playerEditor[input.dataset.playerField] = input.value;
  });
  container.querySelectorAll('[data-time-input]').forEach((input) => {
    state.timeEdits[input.dataset.timeInput] = input.value;
  });
  const search = container.querySelector('#site-player-search');
  if (search) state.playerSearch = search.value;

  const active = container.ownerDocument.activeElement;
  state.focusId = active && active.id && container.contains(active) && active.tagName === 'INPUT' ? active.id : null;
}

function restoreFocus(container) {
  if (!state.focusId) return;
  const input = container.querySelector(`#${state.focusId}`);
  if (!input) return;
  input.focus({ preventScroll: true });
  const end = input.value.length;
  if (typeof input.setSelectionRange === 'function') input.setSelectionRange(end, end);
  state.focusId = null;
}

function rerender(container, focusId) {
  capture(container);
  if (focusId !== undefined) state.focusId = focusId;
  renderSiteAdmin(container);
}

function tabs() {
  return `
    <div class="tabs rise rise-2">
      ${['EVENTS', 'TEAMS', 'PLAYERS'].map((tab) => `
        <button class="tab ${state.tab === tab ? 'active' : ''}" type="button" data-site-tab="${tab}">${tab}</button>
      `).join('')}
    </div>`;
}

function editorPanel(body) {
  return `
    <div style="border: 1px solid var(--gold); background: var(--surface); padding: 20px; display: flex; flex-direction: column; gap: 14px; margin-top: 16px;">
      ${body}
    </div>`;
}

function field(id, label, value, dataAttr, type = 'text') {
  return `
    <label class="field">
      <span class="field-label">${label}</span>
      <input id="${id}" class="input" ${dataAttr} type="${type}" value="${esc(value)}">
    </label>`;
}

function eventPanel(event) {
  if (!event) return '';
  const e = state.eventEditor || {};
  const championFields = event.champion ? `
    ${field('site-event-champion-meta', 'CHAMPION META', e.championMeta || '', 'data-event-field="championMeta"')}
    ${field('site-event-champion-prize', 'CHAMPION PRIZE', e.championPrize || '', 'data-event-field="championPrize"')}
  ` : '';
  return editorPanel(`
    <div class="form-row" style="margin-top: 0;">
      ${field('site-event-name', 'NAME', e.name || '', 'data-event-field="name"')}
      ${field('site-event-prize', 'PRIZE', e.prize || '', 'data-event-field="prize"')}
      ${field('site-event-dates', 'DATES', e.dates || '', 'data-event-field="dates"')}
      ${field('site-event-note', 'NOTE', e.note || '', 'data-event-field="note"')}
      ${championFields}
    </div>
    <div><button class="btn-gold" type="button" data-save-event>SAVE EVENT</button></div>
  `);
}

function scheduleSection(event) {
  const rows = event ? matchesFor(event.code) : [];
  const grid = '180px minmax(0, 1fr) 220px';
  return `
    <div class="rise rise-3" style="margin-top: 34px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        SCHEDULE ${starRule()}
      </div>
      <div class="t-head" style="grid-template-columns: ${grid}; margin-top: 18px;">
        <div>SESSION</div><div>COMPETITORS</div><div>TIME</div>
      </div>
      ${rows.map((m) => {
        const lbl = matchLabel(m);
        const key = String(m.id);
        return `
          <div class="t-row" style="grid-template-columns: ${grid};">
            <div class="mono" style="font-size: 12px; color: var(--text-3);">${esc(lbl.long)}</div>
            <div style="font-weight: 700;">${esc(competitors(m))}</div>
            <input id="site-time-${m.id}" class="input" data-time-input="${m.id}" type="text" value="${esc(state.timeEdits[key] ?? m.time ?? '')}">
          </div>`;
      }).join('')}
      <div style="display: flex; gap: 14px; align-items: center; margin-top: 18px;">
        <button class="btn-gold" type="button" data-save-times>SAVE TIMES</button>
        <span class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--text-3);">EDITS PERSIST IN THIS BROWSER &middot; AUDIENCE PAGES UPDATE IMMEDIATELY</span>
      </div>
    </div>`;
}

function renderEventsTab() {
  const event = TOURNAMENTS.find((t) => t.code === state.eventCode) || TOURNAMENTS[0];
  if (event && state.eventCode !== event.code) fillEventEditor(event);
  return `
    <div class="chips rise rise-2" style="margin-top: 28px;">
      ${TOURNAMENTS.map((t) => `
        <button class="chip-btn ${event && event.code === t.code ? 'sel' : ''}" type="button" data-pick-event="${esc(t.code)}">${esc(t.name)}</button>
      `).join('')}
    </div>
    <div class="rise rise-2">${eventPanel(event)}</div>
    ${scheduleSection(event)}`;
}

function renderTeamsTab() {
  const selected = Number(state.teamId);
  const editor = state.teamEditor || {};
  return `
    <div class="chips rise rise-2" style="margin-top: 28px;">
      ${Object.entries(TEAMS).map(([id, name]) => `
        <button class="chip-btn ${selected === Number(id) ? 'sel' : ''}" type="button" data-pick-team="${id}">${esc(name)}</button>
      `).join('')}
    </div>
    <div class="rise rise-2">
      ${editorPanel(`
        <div class="form-row" style="margin-top: 0;">
          ${field('site-team-name', 'NAME', editor.name || '', 'data-team-field="name"')}
          ${field('site-team-captain', 'CAPTAIN', editor.captain || '', 'data-team-field="captain"')}
          ${field('site-team-founded', 'FOUNDED', editor.founded || '', 'data-team-field="founded"')}
          ${field('site-team-region', 'REGION', editor.region || '', 'data-team-field="region"')}
        </div>
        <div><button class="btn-gold" type="button" data-save-team>SAVE TEAM</button></div>
      `)}
      <div class="mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em; margin-top: 14px;">RENAMES PROPAGATE TO CHAMPION RECORDS AND STANDINGS</div>
    </div>`;
}

function matchingPlayers() {
  const term = state.playerSearch.trim().toLowerCase();
  return Object.entries(PLAYERS)
    .filter(([, p]) => !term || p[0].toLowerCase().includes(term))
    .map(([id, p]) => ({ id: Number(id), player: p }));
}

function playerChips() {
  const matches = matchingPlayers();
  const shown = matches.slice(0, 24);
  const more = matches.length - shown.length;
  return `
    ${shown.map(({ id, player }) => `
      <button class="chip-btn ${state.playerId === id ? 'sel' : ''}" type="button" data-pick-player="${id}">${esc(player[0])}</button>
    `).join('')}
    ${more > 0 ? `<span class="mono" style="font-size: 9px; color: var(--text-3); align-self: center;">${more} MORE &middot; REFINE SEARCH</span>` : ''}`;
}

function playerPanel() {
  const player = state.playerId ? PLAYERS[state.playerId] : null;
  if (!player) return '';
  const editor = state.playerEditor || {};
  const jersey = player[1] > 0
    ? field('site-player-jersey', 'JERSEY', editor.jersey || '', 'data-player-field="jersey"', 'number')
    : '<div class="mono" style="font-size: 10px; letter-spacing: 0.16em; color: var(--text-3); align-self: end;">SOLO COMPETITOR &middot; NO JERSEY</div>';
  return editorPanel(`
    <div class="form-row" style="margin-top: 0;">
      ${field('site-player-ign', 'IGN', editor.ign || '', 'data-player-field="ign"')}
      ${jersey}
    </div>
    <div><button class="btn-gold" type="button" data-save-player>SAVE PLAYER</button></div>
  `);
}

function renderPlayersTab() {
  return `
    <div class="rise rise-2" style="margin-top: 28px;">
      <div class="toolbar">
        <input id="site-player-search" class="search" type="text" placeholder="SEARCH IGN" value="${esc(state.playerSearch)}">
      </div>
      <div class="chips" style="margin-top: 14px;">${playerChips()}</div>
      ${playerPanel()}
      <div class="mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em; margin-top: 14px;">PLAYER RENAMES PROPAGATE TO SOLO MATCHES AND CHAMPION RECORDS</div>
    </div>`;
}

function activeBody() {
  if (state.tab === 'TEAMS') return renderTeamsTab();
  if (state.tab === 'PLAYERS') return renderPlayersTab();
  return renderEventsTab();
}

function wire(container) {
  container.querySelectorAll('[data-site-tab]').forEach((tab) => {
    tab.onclick = () => {
      capture(container);
      state.tab = tab.dataset.siteTab;
      state.focusId = null;
      renderSiteAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-event]').forEach((chip) => {
    chip.onclick = () => {
      const event = TOURNAMENTS.find((t) => t.code === chip.dataset.pickEvent);
      fillEventEditor(event);
      state.focusId = null;
      renderSiteAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-team]').forEach((chip) => {
    chip.onclick = () => {
      fillTeamEditor(chip.dataset.pickTeam);
      state.focusId = null;
      renderSiteAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-player]').forEach((chip) => {
    chip.onclick = () => {
      fillPlayerEditor(chip.dataset.pickPlayer);
      state.focusId = null;
      renderSiteAdmin(container);
    };
  });

  container.querySelectorAll('input').forEach((input) => {
    input.oninput = () => rerender(container, input.id);
  });

  const saveEvent = container.querySelector('[data-save-event]');
  if (saveEvent) {
    saveEvent.onclick = () => {
      capture(container);
      const result = saveEventEdit(state.eventCode, state.eventEditor);
      if (result.ok) {
        const event = TOURNAMENTS.find((t) => t.code === state.eventCode);
        fillEventEditor(event);
        state.notice = { kind: 'ok', text: 'EVENT SAVED &middot; ' + esc(event ? event.name : state.eventEditor.name) };
      } else {
        state.notice = { kind: 'err', text: esc(String(result.error || 'ERROR').toUpperCase()) };
      }
      state.focusId = null;
      renderSiteAdmin(container);
    };
  }

  const saveTimes = container.querySelector('[data-save-times]');
  if (saveTimes) {
    saveTimes.onclick = () => {
      capture(container);
      const event = TOURNAMENTS.find((t) => t.code === state.eventCode);
      const rows = event ? matchesFor(event.code) : [];
      const failed = rows.map((m) => saveMatchTime(m.id, state.timeEdits[String(m.id)])).find((result) => !result.ok);
      if (failed) {
        state.notice = { kind: 'err', text: esc(String(failed.error || 'ERROR').toUpperCase()) };
      } else {
        state.notice = { kind: 'ok', text: 'TIMES SAVED &middot; ' + esc(event ? event.name : 'EVENT') };
      }
      state.focusId = null;
      renderSiteAdmin(container);
    };
  }

  const saveTeam = container.querySelector('[data-save-team]');
  if (saveTeam) {
    saveTeam.onclick = () => {
      capture(container);
      const result = saveTeamEdit(state.teamId, state.teamEditor);
      if (result.ok) {
        fillTeamEditor(state.teamId);
        state.notice = { kind: 'ok', text: 'TEAM SAVED &middot; ' + esc(state.teamEditor.name) };
      } else {
        state.notice = { kind: 'err', text: esc(String(result.error || 'ERROR').toUpperCase()) };
      }
      state.focusId = null;
      renderSiteAdmin(container);
    };
  }

  const savePlayer = container.querySelector('[data-save-player]');
  if (savePlayer) {
    savePlayer.onclick = () => {
      capture(container);
      const result = savePlayerEdit(state.playerId, state.playerEditor);
      if (result.ok) {
        fillPlayerEditor(state.playerId);
        state.notice = { kind: 'ok', text: 'PLAYER SAVED &middot; ' + esc(state.playerEditor.ign) };
      } else {
        state.notice = { kind: 'err', text: esc(String(result.error || 'ERROR').toUpperCase()) };
      }
      state.focusId = null;
      renderSiteAdmin(container);
    };
  }
}

export function renderSiteAdmin(container) {
  ensureEditors();
  const shownNotice = state.notice;
  state.notice = null;

  container.innerHTML = `
    ${plainHead('Site Editor', 'EVERYTHING THE AUDIENCE SEES &middot; EVENTS &middot; TEAMS &middot; PLAYERS', 'ADMIN &middot; MTB EVENTS')}
    ${shownNotice ? `<div class="confirm" style="${shownNotice.kind === 'err' ? 'color: var(--loser);' : ''}">${shownNotice.kind === 'ok' ? STAR(11) : ''}${shownNotice.text}</div>` : ''}
    ${tabs()}
    ${activeBody()}`;
  wire(container);
  restoreFocus(container);
}
