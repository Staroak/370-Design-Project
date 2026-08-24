import assert from 'node:assert/strict';
import {
  TEAMS,
  PLAYERS,
  MATCHES,
  TOURNAMENTS,
  tftStandings,
  tournament,
  saveEventEdit,
  saveTeamEdit,
  savePlayerEdit,
  saveMatchTime,
  storeSnapshot,
} from './data.js';

let assertions = 0;
function check(fn) {
  fn();
  assertions += 1;
}

check(() => assert.equal(tournament('CC').championMeta, '3–0 IN BRACKET · 39 ROUNDS WON'));

check(() => assert.deepEqual(tftStandings('TF'), [
  [1, 'Setsuko#TFT', 1, 2, 15, null, null, 'CHAMPION', 47],
  [2, 'Rerolla#NA1', 3, 1, 14, -1, -1, null, 49],
  [3, 'kiyoomi#EUW', 2, 4, 12, -3, -2, null, 48],
  [4, 'TinyLegend#tft', 5, 3, 10, -5, -2, null, 51],
  [5, 'Augment#0001', 4, 6, 8, -7, -2, null, 50],
  [6, 'HyperRoll#top4', 8, 5, 5, -10, -3, 'TIE ON PTS · BEST FINISH', 54],
  [7, 'Carousel#spin', 6, 7, 5, -10, 0, null, 52],
  [8, 'Fortune#4win', 7, 8, 3, -12, -2, null, 53],
]));

check(() => assert.deepEqual(
  saveEventEdit('CC', { name: 'Creator Cup Plus', prize: 'bad', dates: 'MAR 14–16 2026', note: '', championMeta: '', championPrize: '' }),
  { ok: false, error: 'prize must be a nonnegative number' }
));
check(() => assert.deepEqual(
  saveEventEdit('CC', {
    name: 'Creator Cup Plus',
    prize: '6,500',
    dates: 'MAR 20 2026',
    note: 'Champion · Triple T',
    championMeta: '3–0 IN BRACKET · 39 ROUNDS WON',
    championPrize: '3,500 FIRST PRIZE · PAID',
  }),
  { ok: true }
));
check(() => assert.equal(tournament('CC').name, 'Creator Cup Plus'));
check(() => assert.equal(tournament('CC').prize, '6,500'));
check(() => assert.equal(tournament('CC').month, 'MAR 2026'));
check(() => assert.equal(storeSnapshot().eventEdits.CC.name, 'Creator Cup Plus'));

check(() => assert.deepEqual(
  saveTeamEdit(1, { name: 'Triple T Renamed', captain: 'milkteaboards', founded: 'OCT 08 2025', region: 'NA' }),
  { ok: true }
));
check(() => assert.equal(TEAMS[1], 'Triple T Renamed'));
check(() => assert.equal(tournament('CC').champion, 'Triple T Renamed'));
check(() => assert.deepEqual(
  saveTeamEdit(1, { name: 'the almond joys', captain: 'milkteaboards', founded: 'OCT 08 2025', region: 'NA' }),
  { ok: false, error: 'team name already in use' }
));
check(() => assert.deepEqual(
  saveTeamEdit(1, { name: '<b>x</b>', captain: 'milkteaboards', founded: 'OCT 08 2025', region: 'NA' }),
  { ok: false, error: 'text cannot contain < or >' }
));

check(() => assert.deepEqual(
  savePlayerEdit(55, { ign: 'JstnRenamed#RL', jersey: 42 }),
  { ok: true }
));
check(() => assert.equal(PLAYERS[55][0], 'JstnRenamed#RL'));
check(() => assert.equal(MATCHES.filter((m) => m.solo).every((m) => m.solo.every(([ign]) => ign !== 'Jstn1v1#RL')), true));
check(() => assert.equal(tournament('RL').champion, 'JstnRenamed#RL'));
check(() => assert.deepEqual(
  savePlayerEdit(55, { ign: 'Firstkiller#duel', jersey: 0 }),
  { ok: false, error: 'ign already in use' }
));
check(() => assert.deepEqual(
  savePlayerEdit(55, { ign: '<JstnRenamed#RL', jersey: 0 }),
  { ok: false, error: 'text cannot contain < or >' }
));
check(() => assert.deepEqual(
  savePlayerEdit(1, { ign: PLAYERS[1][0], jersey: 0 }),
  { ok: false, error: 'jersey must be 1 to 99' }
));

check(() => assert.deepEqual(saveMatchTime(18, 'AUG 24 · 19:00'), { ok: true }));
check(() => assert.equal(MATCHES.find((m) => m.id === 18).time, 'AUG 24 · 19:00'));
check(() => assert.deepEqual(saveMatchTime(18, ''), { ok: false, error: 'time required' }));
check(() => assert.deepEqual(saveMatchTime(999, 'AUG 24 · 19:00'), { ok: false, error: 'match not found' }));

check(() => assert.equal(TOURNAMENTS.length >= 6, true));

console.log(`SMOKE OK · ${assertions} assertions`);
