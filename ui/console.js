// Star Tournaments operations console.

import {
  TOURNAMENTS,
  TEAMS,
  matchesFor,
  tournament,
  openMatches,
  recordResult,
  createTournament,
  resetDemo,
} from './data.js';
import { STAR, glyph, starRule, plainHead } from './ui-kit.js';

let editing = null;
let selA = null;
let selB = null;
let scoreA = '';
let scoreB = '';
let notice = null;
let newName = '';
let newPrize = '';
let newDates = '';
const newTeams = new Set();

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function sideName(s) {
  return typeof s === 'number' ? TEAMS[s] : s;
}

function matchLabel(m) {
  const t = tournament(m.t);
  const maxR = Math.max(...matchesFor(m.t).map((x) => x.round));
  if (t && t.format === 'series') return { long: `GAME ${m.round}`, short: `G${m.round}` };
  if (t && t.format === 'points') return { long: `LOBBY ${m.round}`, short: `L${m.round}` };
  if (m.round === maxR) return { long: 'GRAND FINAL', short: 'F' };
  if (m.round === maxR - 1) return { long: `SEMIFINAL ${m.slot}`, short: `SF${m.slot}` };
  return { long: `QUARTERFINAL ${m.slot}`, short: `QF${m.slot}` };
}

function cellSide(side, won) {
  return `
    <div class="mcell-side ${won ? 'win' : 'lose'}">
      <div class="mcell-name">${esc(sideName(side[0]))}</div>
      <div class="mcell-score">${esc(side[1])}</div>
    </div>`;
}

function dimRows(m) {
  const names = m.hint ? m.hint.split(' vs ') : ['TBD', 'TBD'];
  return `
    <div class="mcell-side lose"><div class="mcell-name">${esc(names[0] || 'TBD')}</div><div class="mcell-score">&#8211;</div></div>
    <div class="mcell-rule"></div>
    <div class="mcell-side lose"><div class="mcell-name">${esc(names[1] || 'TBD')}</div><div class="mcell-score">&#8211;</div></div>`;
}

function teamChips(eligible, side) {
  const selected = side === 'a' ? selA : selB;
  const other = side === 'a' ? selB : selA;
  return eligible.map((id) => `
    <button
      class="chip-btn ${selected === id ? 'sel' : ''}"
      type="button"
      data-side="${side}"
      data-team="${id}"
      ${other === id ? 'disabled' : ''}
    >${esc(TEAMS[id])}</button>`).join('');
}

function editor(m, eligible) {
  return `
    <div class="mcell-editor">
      <div class="editor-label">TEAM A</div>
      <div class="chips">${teamChips(eligible, 'a')}</div>
      <div class="editor-label">TEAM B</div>
      <div class="chips">${teamChips(eligible, 'b')}</div>
      <div style="display: flex; gap: 14px; align-items: flex-end; flex-wrap: wrap;">
        <label class="field">
          <span class="field-label">SCORE A</span>
          <input class="score-input" id="score-a" type="number" min="0" max="99" value="${esc(scoreA)}">
        </label>
        <label class="field">
          <span class="field-label">SCORE B</span>
          <input class="score-input" id="score-b" type="number" min="0" max="99" value="${esc(scoreB)}">
        </label>
        <button class="btn-gold" type="button" data-save="${m.id}">SAVE RESULT</button>
        <button class="btn-quiet" type="button" data-cancel>CANCEL</button>
      </div>
    </div>`;
}

function consoleCell(m, openById) {
  const lbl = matchLabel(m);
  if (m.sides) {
    return `
      <div class="mcell">
        ${cellSide(m.sides[0], true)}
        <div class="mcell-rule"></div>
        ${cellSide(m.sides[1], false)}
        <div class="mcell-foot">${esc(lbl.long)} &middot; ${esc(m.time)} &middot; RECORDED</div>
      </div>`;
  }

  const open = openById.get(m.id);
  const eligible = open ? open.eligible : [];
  if (editing === m.id) {
    return `
      <div class="mcell editing">
        ${dimRows(m)}
        ${editor(m, eligible)}
      </div>`;
  }

  if (eligible.length >= 2) {
    return `
      <div class="mcell open-cell" data-edit="${m.id}">
        ${dimRows(m)}
        <div class="mcell-foot" style="color: var(--gold);">ENTER RESULT &middot; ${esc(lbl.long)} &middot; ${esc(m.time)}</div>
      </div>`;
  }

  return `
    <div class="mcell">
      ${dimRows(m)}
      <div class="mcell-foot">AWAITING PREVIOUS ROUND &middot; ${esc(lbl.long)}</div>
    </div>`;
}

function statusChip(t) {
  if (t.status === 'live') return '<span class="chip chip-live">LIVE</span>';
  if (t.status === 'upcoming') return '<span class="chip" style="color: var(--text-2);">UPCOMING</span>';
  return '<span class="chip chip-done">COMPLETED</span>';
}

function bracket(t, openById) {
  const ms = matchesFor(t.code);
  const maxR = Math.max(...ms.map((m) => m.round));
  const names = maxR === 3 ? ['QUARTERFINALS', 'SEMIFINALS', 'FINAL'] : ['SEMIFINALS', 'FINAL'];
  const cols = [];

  for (let r = 1; r <= maxR; r += 1) {
    const inRound = ms.filter((m) => m.round === r).sort((a, b) => a.slot - b.slot);
    cols.push(`
      <div class="b-col">
        <div class="b-col-label">${names[r - 1]}</div>
        <div class="b-col-body">${inRound.map((m) => consoleCell(m, openById)).join('')}</div>
      </div>`);
  }

  return `<div class="bracket rise rise-2" style="grid-template-columns: repeat(${cols.length}, 1fr);">${cols.join('')}</div>`;
}

function tournamentSection(t, openById) {
  return `
    <div class="rise rise-2" style="margin-top: 42px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">
        ${glyph(t.glyph, 28)}
        <span>${esc(t.name.toUpperCase())}</span>
        ${statusChip(t)}
        <span class="mono" style="font-size: 10px; color: var(--text-3);">${esc(t.dates)}</span>
        ${starRule()}
      </div>
      ${bracket(t, openById)}
    </div>`;
}

function createSection() {
  return `
    <div class="rise rise-3" style="margin-top: 42px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">NEW TOURNAMENT ${starRule()}</div>
      <div class="form-row">
        <label class="field">
          <span class="field-label">NAME</span>
          <input class="input" data-new-name type="text" value="${esc(newName)}">
        </label>
        <label class="field">
          <span class="field-label">PRIZE</span>
          <input class="input" data-new-prize type="number" min="500" placeholder="2500" value="${esc(newPrize)}">
        </label>
        <label class="field">
          <span class="field-label">DATES</span>
          <input class="input" data-new-dates type="text" placeholder="OCT 10&#8211;11 2026" value="${esc(newDates)}">
        </label>
      </div>
      <div class="editor-label" style="margin-top: 20px;">PICK EXACTLY 4 TEAMS</div>
      <div class="chips" style="margin-top: 10px;">
        ${Object.entries(TEAMS).map(([id, name]) => `
          <button class="chip-btn ${newTeams.has(Number(id)) ? 'sel' : ''}" type="button" data-new-team="${id}">${esc(name)}</button>
        `).join('')}
      </div>
      <div style="display: flex; align-items: center; gap: 18px; margin-top: 20px;">
        <button class="btn-gold" type="button" data-create>CREATE TOURNAMENT</button>
        <span class="mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em;">VALORANT &middot; SINGLE ELIMINATION &middot; DEMO SCOPE</span>
      </div>
    </div>`;
}

function demoSection() {
  return `
    <div class="rise rise-4" style="margin-top: 42px;">
      <div class="section-label" style="padding-bottom: 10px; border-bottom: 1px solid var(--line-strong);">DEMO DATA ${starRule()}</div>
      <div class="mono" style="font-size: 10px; color: var(--text-3); letter-spacing: 0.16em; margin-top: 18px;">ENTRIES PERSIST IN THIS BROWSER ONLY &middot; RESET RESTORES THE SEED DATA</div>
      <button class="btn-quiet" type="button" data-reset style="margin-top: 18px;">RESET DEMO DATA</button>
    </div>`;
}

function capture(container) {
  if (!container) return;
  const a = container.querySelector('#score-a');
  const b = container.querySelector('#score-b');
  if (a) scoreA = a.value;
  if (b) scoreB = b.value;
  const name = container.querySelector('[data-new-name]');
  const prize = container.querySelector('[data-new-prize]');
  const dates = container.querySelector('[data-new-dates]');
  if (name) newName = name.value;
  if (prize) newPrize = prize.value;
  if (dates) newDates = dates.value;
}

function clearEditing() {
  editing = null;
  selA = null;
  selB = null;
  scoreA = '';
  scoreB = '';
}

function clearCreateForm() {
  newName = '';
  newPrize = '';
  newDates = '';
  newTeams.clear();
}

function wire(container) {
  container.querySelectorAll('[data-edit]').forEach((cell) => {
    cell.onclick = () => {
      const id = Number(cell.dataset.edit);
      const open = openMatches().find((m) => m.id === id);
      editing = id;
      scoreA = '';
      scoreB = '';
      if (open && open.eligible.length === 2) {
        selA = open.eligible[0];
        selB = open.eligible[1];
      } else {
        selA = null;
        selB = null;
      }
      renderConsole(container);
    };
  });

  container.querySelectorAll('[data-side][data-team]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      const teamId = Number(chip.dataset.team);
      if (chip.dataset.side === 'a') {
        selA = selA === teamId ? null : teamId;
        if (selB === selA) selB = null;
      } else {
        selB = selB === teamId ? null : teamId;
        if (selA === selB) selA = null;
      }
      renderConsole(container);
    };
  });

  const saveButton = container.querySelector('[data-save]');
  if (saveButton) {
    saveButton.onclick = () => {
      capture(container);
      const id = Number(saveButton.dataset.save);
      const open = openMatches().find((m) => m.id === id);
      if (!selA || !selB || scoreA === '' || scoreB === '') {
        notice = { kind: 'err', text: 'PICK BOTH TEAMS AND SCORES' };
        renderConsole(container);
        return;
      }
      const result = recordResult(id, selA, scoreA, selB, scoreB);
      if (result.ok) {
        notice = { kind: 'ok', text: 'RESULT SAVED &middot; ' + esc(open ? open.label : `SESSION ${id}`) };
        clearEditing();
      } else {
        notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      }
      renderConsole(container);
    };
  }

  const cancelButton = container.querySelector('[data-cancel]');
  if (cancelButton) {
    cancelButton.onclick = () => {
      clearEditing();
      renderConsole(container);
    };
  }

  container.querySelectorAll('[data-new-team]').forEach((chip) => {
    chip.onclick = () => {
      capture(container);
      const teamId = Number(chip.dataset.newTeam);
      if (newTeams.has(teamId)) newTeams.delete(teamId);
      else newTeams.add(teamId);
      renderConsole(container);
    };
  });

  const createButton = container.querySelector('[data-create]');
  if (createButton) {
    createButton.onclick = () => {
      capture(container);
      if (!newName.trim()) {
        notice = { kind: 'err', text: 'NAME REQUIRED' };
        renderConsole(container);
        return;
      }
      if (newTeams.size !== 4) {
        notice = { kind: 'err', text: 'PICK EXACTLY 4 TEAMS' };
        renderConsole(container);
        return;
      }
      const name = newName.trim();
      const result = createTournament({
        name,
        prize: newPrize,
        dates: newDates,
        teams: [...newTeams],
      });
      if (result.ok) {
        notice = { kind: 'ok', text: 'CREATED &middot; ' + esc(name) + ' &middot; OPEN IT FROM EVENTS' };
        clearCreateForm();
      } else {
        notice = { kind: 'err', text: String(result.error || 'ERROR').toUpperCase() };
      }
      renderConsole(container);
    };
  }

  const resetButton = container.querySelector('[data-reset]');
  if (resetButton) resetButton.onclick = resetDemo;
}

export function renderConsole(container) {
  const shownNotice = notice;
  notice = null;
  const openById = new Map(openMatches().map((m) => [m.id, m]));
  const events = TOURNAMENTS.filter((t) => {
    if (t.format !== 'elim') return false;
    const ms = matchesFor(t.code);
    return t.status === 'live' || t.status === 'upcoming' || ms.some((m) => m.sides === null);
  });

  container.innerHTML = `
    ${plainHead('Operations Console', 'RECORD RESULTS &middot; CREATE EVENTS &middot; BACKED BY SP_RECORD_PLACEMENT AND SP_REGISTER_TEAM', 'ADMIN &middot; MTB EVENTS')}
    ${shownNotice ? `<div class="confirm" style="${shownNotice.kind === 'err' ? 'color: var(--loser);' : ''}">${shownNotice.kind === 'ok' ? STAR(11) : ''}${shownNotice.text}</div>` : ''}
    ${events.map((t) => tournamentSection(t, openById)).join('')}
    ${createSection()}
    ${demoSection()}`;
  wire(container);
}
