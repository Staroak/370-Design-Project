// Creator Management admin page.

import {
  CREATORS,
  CREATOR_ASSIGNMENTS,
  TOURNAMENTS,
  assignCreator,
  removeAssignment,
  saveCreator,
  tournament,
} from './data.js';
import { STAR, plainHead, starRule, platIcon } from './ui-kit.js';

const roles = ['streamer', 'host', 'caster', 'observer'];
const platformFilters = [
  ['all', 'ALL'],
  ['tw', platIcon('tw')],
  ['ig', platIcon('ig')],
  ['x', platIcon('x')],
];
const assignmentFilters = [
  ['all', 'ALL'],
  ['assigned', 'ASSIGNED'],
  ['unassigned', 'UNASSIGNED'],
];

const state = {
  search: '',
  platFilter: 'all',
  assignFilter: 'all',
  editingId: null,
  editor: {
    name: '',
    twitch: '',
    instagram: '',
    twitter: '',
    pic: '',
  },
  composer: {
    creatorSearch: '',
    selCreator: null,
    selEvent: null,
    selRole: null,
    rate: '',
  },
  assignEventFilter: 'all',
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

function creatorName(id) {
  const creator = CREATORS.find((entry) => entry.id === Number(id));
  return creator ? creator.name : 'Unknown Creator';
}

function eventName(code) {
  const event = tournament(code);
  return event ? event.name : 'Unknown event';
}

function initial(name) {
  return String(name || '?').trim().charAt(0).toUpperCase() || '?';
}

function creatorAvatar(creator) {
  const letter = esc(initial(creator.name));
  if (creator.pic) {
    return `<div class="avatar"><img src="${esc(creator.pic)}" alt="" onerror="this.remove()">${letter}</div>`;
  }
  return `<div class="avatar">${letter}</div>`;
}

function assignmentCount(creatorId) {
  return CREATOR_ASSIGNMENTS.filter((assignment) => assignment.creatorId === creatorId).length;
}

function assignedCreatorIds() {
  return new Set(CREATOR_ASSIGNMENTS.map((assignment) => assignment.creatorId));
}

function hasPlatform(creator, key) {
  if (key === 'tw') return Boolean(creator.twitch);
  if (key === 'ig') return Boolean(creator.instagram);
  if (key === 'x') return Boolean(creator.twitter);
  return true;
}

function matchesSearch(creator) {
  const term = state.search.trim().toLowerCase();
  if (!term) return true;
  return [
    creator.name,
    creator.twitch,
    creator.instagram,
    creator.twitter,
  ].some((value) => String(value || '').toLowerCase().includes(term));
}

function filteredCreators() {
  return CREATORS
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
    .filter((creator) => {
      const count = assignmentCount(creator.id);
      const assignOk = state.assignFilter === 'all'
        || (state.assignFilter === 'assigned' && count > 0)
        || (state.assignFilter === 'unassigned' && count === 0);
      return matchesSearch(creator) && hasPlatform(creator, state.platFilter) && assignOk;
    });
}

function eventChoices() {
  return TOURNAMENTS.map((event) => [event.code, event.name]);
}

function statStrip() {
  const assigned = assignedCreatorIds().size;
  const total = CREATORS.length;
  return `
    <div class="stat-strip">
      <div class="stat"><div class="stat-label">CREATORS</div><div class="stat-value">${total}</div></div>
      <div class="stat"><div class="stat-label">ASSIGNED</div><div class="stat-value">${assigned}</div></div>
      <div class="stat"><div class="stat-label">UNASSIGNED</div><div class="stat-value">${total - assigned}</div></div>
    </div>`;
}

function filterChips(items, active, dataName) {
  // Labels are our own markup (text or platIcon SVG); keys are the only
  // untrusted-ish values here.
  return items.map(([key, label]) => `
    <button class="chip-btn ${active === key ? 'sel' : ''}" type="button" data-${dataName}="${esc(key)}">${label}</button>
  `).join('');
}

function editorPanel() {
  return `
    <div style="border: 1px solid var(--gold); background: var(--surface); padding: 20px; display: flex; flex-direction: column; gap: 14px; margin-top: 16px;">
      <div class="form-row" style="margin-top: 0;">
        <label class="field">
          <span class="field-label">DISPLAY NAME</span>
          <input id="creator-form-name" class="input" data-form-name type="text" value="${esc(state.editor.name)}">
        </label>
        <label class="field">
          <span class="field-label">TWITCH</span>
          <input id="creator-form-twitch" class="input" data-form-twitch type="text" value="${esc(state.editor.twitch)}">
        </label>
        <label class="field">
          <span class="field-label">INSTAGRAM</span>
          <input id="creator-form-instagram" class="input" data-form-instagram type="text" value="${esc(state.editor.instagram)}">
        </label>
        <label class="field">
          <span class="field-label">TWITTER</span>
          <input id="creator-form-twitter" class="input" data-form-twitter type="text" value="${esc(state.editor.twitter)}">
        </label>
        <label class="field">
          <span class="field-label">PROFILE PIC URL</span>
          <input id="creator-form-pic" class="input" data-form-pic type="text" value="${esc(state.editor.pic)}">
        </label>
      </div>
      <div class="mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em;">AT LEAST ONE LINK REQUIRED &middot; MIRRORS THE DATABASE CHECK CONSTRAINT</div>
      <div style="display: flex; gap: 14px; align-items: center;">
        <button class="btn-gold" type="button" data-save-creator>SAVE CREATOR</button>
        <button class="btn-quiet" type="button" data-cancel-creator>CANCEL</button>
      </div>
    </div>`;
}

function creatorCard(creator) {
  const count = assignmentCount(creator.id);
  const selected = state.editingId === creator.id;
  return `
    <button class="ccard ${selected ? 'sel' : ''}" type="button" data-card-creator="${creator.id}">
      ${creatorAvatar(creator)}
      <span class="ccard-body">
        <span class="ccard-name">${esc(creator.name)}</span>
        <span class="ccard-meta">
          <span class="plat-tag ${creator.twitch ? 'on' : ''}">${platIcon('tw', 11)}</span>
          <span class="plat-tag ${creator.instagram ? 'on' : ''}">${platIcon('ig', 11)}</span>
          <span class="plat-tag ${creator.twitter ? 'on' : ''}">${platIcon('x', 11)}</span>
          ${count ? `<span class="mono" style="font-size: 9px; color: var(--text-3);">${count} EV</span>` : ''}
        </span>
      </span>
    </button>`;
}

function registrySection() {
  const creators = filteredCreators();
  return `
    <div class="rise rise-2" style="margin-top: 42px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">CREATOR REGISTRY ${starRule()}</div>
      <div class="toolbar">
        <input id="creator-search" class="search" type="text" placeholder="SEARCH NAME OR LINK" value="${esc(state.search)}">
        <div class="chips">${filterChips(platformFilters, state.platFilter, 'platform-filter')}</div>
        <div class="chips">${filterChips(assignmentFilters, state.assignFilter, 'creator-assignment-filter')}</div>
        <button class="btn-quiet" type="button" data-add-creator>ADD CREATOR</button>
      </div>
      <div class="count-line">${CREATORS.length} CREATORS &middot; ${creators.length} MATCH</div>
      ${state.editingId !== null ? editorPanel() : ''}
      <div class="cardgrid">${creators.map((creator) => creatorCard(creator)).join('')}</div>
    </div>`;
}

function assignmentRows(assignments) {
  const grid = 'minmax(0,1fr) 240px 160px 110px 120px 110px';
  return `
    <div class="t-head" style="grid-template-columns: ${grid}; margin-top: 20px;">
      <div>CREATOR</div><div>EVENT</div><div>ROLE</div><div class="right">RATE</div><div>STATUS</div><div class="right"></div>
    </div>
    ${assignments.map((assignment) => {
      const event = tournament(assignment.code);
      return `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${esc(creatorName(assignment.creatorId))}</div>
          <div style="color: var(--text-2);">${esc(event ? event.name : 'Unknown event')}</div>
          <div class="mono" style="font-size: 12px;">${esc(assignment.role)}</div>
          <div class="num">${esc(assignment.rate)}</div>
          <div><span class="pill pill-ok">ACTIVE</span></div>
          <div class="right"><button class="btn-quiet" type="button" data-remove-creator="${assignment.creatorId}" data-remove-code="${esc(assignment.code)}">REMOVE</button></div>
        </div>`;
    }).join('')}`;
}

function filteredAssignments() {
  return CREATOR_ASSIGNMENTS
    .filter((assignment) => state.assignEventFilter === 'all' || assignment.code === state.assignEventFilter)
    .slice()
    .sort((a, b) => {
      const codeOrder = a.code.localeCompare(b.code);
      if (codeOrder) return codeOrder;
      return creatorName(a.creatorId).localeCompare(creatorName(b.creatorId), undefined, { sensitivity: 'base' });
    });
}

function eventFilterChips() {
  const chips = [['all', 'ALL'], ...eventChoices()];
  return filterChips(chips, state.assignEventFilter, 'assignment-event-filter');
}

function creatorChips() {
  const term = state.composer.creatorSearch.trim().toLowerCase();
  const matches = CREATORS
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
    .filter((creator) => !term || creator.name.toLowerCase().includes(term));
  const shown = matches.slice(0, 12);
  const more = matches.length - shown.length;
  return `
    ${shown.map((creator) => `
      <button class="chip-btn ${state.composer.selCreator === creator.id ? 'sel' : ''}" type="button" data-pick-creator="${creator.id}">${esc(creator.name)}</button>
    `).join('')}
    ${more > 0 ? `<span class="mono" style="font-size: 9px; color: var(--text-3); align-self: center;">${more} MORE &middot; REFINE SEARCH</span>` : ''}`;
}

function eventChips() {
  return TOURNAMENTS.map((event) => `
    <button class="chip-btn ${state.composer.selEvent === event.code ? 'sel' : ''}" type="button" title="${esc(event.name)}" data-pick-event="${esc(event.code)}">${esc(event.name)}</button>
  `).join('');
}

function roleChips() {
  return roles.map((roleName) => `
    <button class="chip-btn ${state.composer.selRole === roleName ? 'sel' : ''}" type="button" data-pick-role="${esc(roleName)}">${esc(roleName.toUpperCase())}</button>
  `).join('');
}

function composer() {
  const selected = state.composer.selCreator ? creatorName(state.composer.selCreator) : '';
  return `
    <div style="margin-top: 28px;">
      <div class="editor-label">NEW ASSIGNMENT</div>
      <div class="editor-label" style="margin-top: 16px;">CREATOR</div>
      <div class="toolbar" style="margin-top: 10px;">
        ${selected ? `<span class="mono gold" style="font-size: 11px; letter-spacing: 0.12em;">${esc(selected)}</span>` : ''}
        <input id="assign-search" class="search" type="text" placeholder="FIND CREATOR" value="${esc(state.composer.creatorSearch)}">
      </div>
      <div class="chips" style="margin-top: 10px;">${creatorChips()}</div>
      <div class="editor-label" style="margin-top: 16px;">EVENT</div>
      <div class="chips" style="margin-top: 10px;">${eventChips()}</div>
      <div class="editor-label" style="margin-top: 16px;">ROLE</div>
      <div class="chips" style="margin-top: 10px;">${roleChips()}</div>
      <div class="form-row">
        <label class="field">
          <span class="field-label">RATE</span>
          <input id="assignment-rate" class="input" data-assignment-rate type="number" min="0" value="${esc(state.composer.rate)}">
        </label>
        <button class="btn-gold" type="button" data-assign>ASSIGN</button>
      </div>
    </div>`;
}

function assignmentsSection() {
  const assignments = filteredAssignments();
  return `
    <div class="rise rise-3" style="margin-top: 42px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">EVENT ASSIGNMENTS ${starRule()}</div>
      <div class="toolbar">${eventFilterChips()}</div>
      <div class="count-line">${assignments.length} SHOWN &middot; ${CREATOR_ASSIGNMENTS.length} TOTAL</div>
      ${assignmentRows(assignments)}
      ${composer()}
    </div>`;
}

function capture(container) {
  if (!container) return;
  const creatorSearch = container.querySelector('#creator-search');
  const assignSearch = container.querySelector('#assign-search');
  const name = container.querySelector('[data-form-name]');
  const twitch = container.querySelector('[data-form-twitch]');
  const instagram = container.querySelector('[data-form-instagram]');
  const twitter = container.querySelector('[data-form-twitter]');
  const pic = container.querySelector('[data-form-pic]');
  const assignmentRate = container.querySelector('[data-assignment-rate]');
  if (creatorSearch) state.search = creatorSearch.value;
  if (assignSearch) state.composer.creatorSearch = assignSearch.value;
  if (name) state.editor.name = name.value;
  if (twitch) state.editor.twitch = twitch.value;
  if (instagram) state.editor.instagram = instagram.value;
  if (twitter) state.editor.twitter = twitter.value;
  if (pic) state.editor.pic = pic.value;
  if (assignmentRate) state.composer.rate = assignmentRate.value;

  const active = container.ownerDocument.activeElement;
  state.focusId = active && active.id && container.contains(active) && active.tagName === 'INPUT' ? active.id : null;
}

function rerender(container, focusId) {
  capture(container);
  if (focusId !== undefined) state.focusId = focusId;
  renderCreatorsAdmin(container);
}

function fillEditor(creator) {
  state.editingId = creator ? creator.id : 'new';
  state.editor.name = creator ? creator.name : '';
  state.editor.twitch = creator ? creator.twitch : '';
  state.editor.instagram = creator ? creator.instagram : '';
  state.editor.twitter = creator ? creator.twitter : '';
  state.editor.pic = creator ? creator.pic : '';
}

function clearEditor() {
  state.editingId = null;
  state.editor.name = '';
  state.editor.twitch = '';
  state.editor.instagram = '';
  state.editor.twitter = '';
  state.editor.pic = '';
}

function clearComposer() {
  state.composer.selCreator = null;
  state.composer.selEvent = null;
  state.composer.selRole = null;
  state.composer.rate = '';
  state.composer.creatorSearch = '';
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

function wire(container) {
  const creatorSearch = container.querySelector('#creator-search');
  if (creatorSearch) {
    creatorSearch.oninput = () => {
      state.search = creatorSearch.value;
      rerender(container, 'creator-search');
    };
  }

  const assignSearch = container.querySelector('#assign-search');
  if (assignSearch) {
    assignSearch.oninput = () => {
      state.composer.creatorSearch = assignSearch.value;
      rerender(container, 'assign-search');
    };
  }

  container.querySelectorAll('[data-platform-filter]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      state.platFilter = chip.dataset.platformFilter;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  container.querySelectorAll('[data-creator-assignment-filter]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      state.assignFilter = chip.dataset.creatorAssignmentFilter;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  container.querySelectorAll('[data-assignment-event-filter]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      state.assignEventFilter = chip.dataset.assignmentEventFilter;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  const addButton = container.querySelector('[data-add-creator]');
  if (addButton) {
    addButton.onclick = () => {
      capture(container);
      fillEditor(null);
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  }

  container.querySelectorAll('[data-card-creator]').forEach((card) => {
    card.onclick = () => {
      capture(container);
      const creator = CREATORS.find((entry) => entry.id === Number(card.dataset.cardCreator));
      if (creator) fillEditor(creator);
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  const saveButton = container.querySelector('[data-save-creator]');
  if (saveButton) {
    saveButton.onclick = () => {
      capture(container);
      const cleanName = state.editor.name.trim();
      const result = saveCreator(state.editingId === 'new' ? null : state.editingId, {
        name: state.editor.name,
        twitch: state.editor.twitch,
        instagram: state.editor.instagram,
        twitter: state.editor.twitter,
        pic: state.editor.pic,
      });
      if (result.ok) {
        state.notice = { kind: 'ok', text: 'CREATOR SAVED &middot; ' + esc(cleanName) };
        clearEditor();
      } else {
        state.notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      }
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  }

  const cancelButton = container.querySelector('[data-cancel-creator]');
  if (cancelButton) {
    cancelButton.onclick = () => {
      capture(container);
      clearEditor();
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  }

  container.querySelectorAll('[data-remove-creator][data-remove-code]').forEach((button) => {
    button.onclick = () => {
      capture(container);
      removeAssignment(button.dataset.removeCreator, button.dataset.removeCode);
      state.notice = { kind: 'ok', text: 'ASSIGNMENT REMOVED &middot; ' + esc(eventName(button.dataset.removeCode).toUpperCase()) };
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-creator]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      const id = Number(chip.dataset.pickCreator);
      state.composer.selCreator = state.composer.selCreator === id ? null : id;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-event]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      const code = chip.dataset.pickEvent;
      state.composer.selEvent = state.composer.selEvent === code ? null : code;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  container.querySelectorAll('[data-pick-role]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      const role = chip.dataset.pickRole;
      state.composer.selRole = state.composer.selRole === role ? null : role;
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  });

  const assignButton = container.querySelector('[data-assign]');
  if (assignButton) {
    assignButton.onclick = () => {
      capture(container);
      if (!state.composer.selCreator || !state.composer.selEvent || !state.composer.selRole || state.composer.rate === '') {
        state.notice = { kind: 'err', text: 'PICK CREATOR EVENT ROLE AND RATE' };
        state.focusId = null;
        renderCreatorsAdmin(container);
        return;
      }
      const result = assignCreator({
        creatorId: state.composer.selCreator,
        code: state.composer.selEvent,
        role: state.composer.selRole,
        rate: state.composer.rate,
      });
      if (result.ok) {
        state.notice = { kind: 'ok', text: 'ASSIGNMENT SAVED &middot; ' + esc(creatorName(state.composer.selCreator)) + ' &middot; ' + esc(eventName(state.composer.selEvent).toUpperCase()) };
        clearComposer();
      } else {
        state.notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      }
      state.focusId = null;
      renderCreatorsAdmin(container);
    };
  }
}

export function renderCreatorsAdmin(container) {
  const shownNotice = state.notice;
  state.notice = null;

  container.innerHTML = `
    ${plainHead('Creator Management', 'CREATOR REGISTRY &middot; LINKS &middot; EVENT ASSIGNMENTS &middot; BACKED BY THE CREATORS TABLE', 'ADMIN &middot; MTB EVENTS')}
    ${shownNotice ? `<div class="confirm" style="${shownNotice.kind === 'err' ? 'color: var(--loser);' : ''}">${shownNotice.kind === 'ok' ? STAR(11) : ''}${shownNotice.text}</div>` : ''}
    ${statStrip()}
    ${registrySection()}
    ${assignmentsSection()}`;
  wire(container);
  restoreFocus(container);
}
