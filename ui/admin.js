// Star Tournaments · organization admin page.

import { ADMIN } from './data.js';
import { STAR, plainHead } from './ui-kit.js';

let activeTab = 'FINANCIALS';

function money(n) {
  return n.toLocaleString('en-US');
}

function profitCell(n) {
  const value = `${n >= 0 ? '+' : '-'}${money(Math.abs(n))}`;
  const neg = n < 0;
  return `<div class="num-strong ${neg ? 'neg' : ''}" style="${neg ? 'color: var(--loser);' : ''}">${value}</div>`;
}

function renderFinancials() {
  const grid = 'minmax(0, 1fr) 150px 150px 150px';
  const revenue = ADMIN.financials.reduce((sum, [, r]) => sum + r, 0);
  const expense = ADMIN.financials.reduce((sum, [, , e]) => sum + e, 0);
  const profit = revenue - expense;

  return `
    <div class="rise rise-2">
      <div class="stat-strip">
        <div class="stat"><div class="stat-label">SEASON REVENUE</div><div class="stat-value">${money(revenue)}</div></div>
        <div class="stat"><div class="stat-label">SEASON EXPENSE</div><div class="stat-value">${money(expense)}</div></div>
        <div class="stat"><div class="stat-label">SEASON PROFIT</div><div class="stat-value gold">+${money(profit)}</div></div>
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>EVENT</div><div class="right">REVENUE</div><div class="right">EXPENSE</div><div class="right">PROFIT</div>
      </div>
      ${ADMIN.financials.map(([event, revenue, expense]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${event}</div>
          <div class="num">${money(revenue)}</div>
          <div class="num">${money(expense)}</div>
          ${profitCell(revenue - expense)}
        </div>`).join('')}
    </div>`;
}

function renderOutstanding() {
  const grid = '110px minmax(0, 1fr) 260px 120px 110px';
  const total = ADMIN.outstanding.reduce((sum, [, , , amount]) => sum + amount, 0);

  return `
    <div class="rise rise-2">
      <div class="stat-strip">
        <div class="stat"><div class="stat-label">TOTAL OUTSTANDING</div><div class="stat-value gold">${money(total)}</div></div>
        <div class="stat"><div class="stat-label">ITEMS</div><div class="stat-value">${ADMIN.outstanding.length}</div></div>
      </div>
    </div>
    <div class="rise rise-3" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>TYPE</div><div>PAYEE</div><div>EVENT</div><div class="right">AMOUNT</div><div>STATUS</div>
      </div>
      ${ADMIN.outstanding.map(([type, payee, event, amount]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div class="mono" style="font-size: 12px; color: var(--text-3);">${type}</div>
          <div style="font-weight: 700;">${payee}</div>
          <div style="color: var(--text-2);">${event}</div>
          <div class="num-strong">${money(amount)}</div>
          <div><span class="pill pill-due">DUE</span></div>
        </div>`).join('')}
    </div>`;
}

function renderMembers() {
  const grid = 'minmax(0, 1fr) 280px 160px 140px';

  return `
    <div class="rise rise-2" style="margin-top: 36px;">
      <div class="t-head" style="grid-template-columns: ${grid};">
        <div>NAME</div><div>EMAIL</div><div>ROLE</div><div class="right">SINCE</div>
      </div>
      ${ADMIN.members.map(([name, email, role, since]) => `
        <div class="t-row" style="grid-template-columns: ${grid};">
          <div style="font-weight: 700;">${role === 'admin' ? `${STAR(10)} ` : ''}${name}</div>
          <div class="mono" style="font-size: 12px; color: var(--text-2);">${email}</div>
          <div class="mono" style="font-size: 12px;">${role.toUpperCase()}</div>
          <div class="num">${since}</div>
        </div>`).join('')}
    </div>`;
}

function renderPanel(panel) {
  if (activeTab === 'OUTSTANDING') panel.innerHTML = renderOutstanding();
  else if (activeTab === 'MEMBERS') panel.innerHTML = renderMembers();
  else panel.innerHTML = renderFinancials();
}

function wireTabs(container) {
  container.querySelectorAll('.tab').forEach((tab) => {
    tab.classList.toggle('active', tab.dataset.tab === activeTab);
    tab.onclick = () => {
      activeTab = tab.dataset.tab;
      renderPanel(container.querySelector('[data-admin-panel]'));
      wireTabs(container);
    };
  });
}

export function renderAdmin(container) {
  container.innerHTML = `
    ${plainHead('Organization Admin', 'V_ORG_FINANCIALS · V_OUTSTANDING_PAYMENTS · V_ORG_MEMBERSHIP · MTB EVENTS ONLY', 'ADMIN · MTB EVENTS')}
    <div class="tabs rise rise-2">
      <button class="tab" type="button" data-tab="FINANCIALS">FINANCIALS</button>
      <button class="tab" type="button" data-tab="OUTSTANDING">OUTSTANDING</button>
      <button class="tab" type="button" data-tab="MEMBERS">MEMBERS</button>
    </div>
    <div data-admin-panel></div>`;
  renderPanel(container.querySelector('[data-admin-panel]'));
  wireTabs(container);
}
