// Star Tournaments · demo data, mirrored from the design_project_370 seed
// (02_insert_data.sql + 18_ui_seed_fill.sql). No em dashes in any copy.

export const TEAMS = {
  1: "Triple T's Sahurs",
  2: 'The Almond Joys',
  3: 'Monkey Lovers',
  4: 'Elements of Harmony',
  5: 'MENAces',
  6: 'valorant enjoyers',
  7: 'AURAA Farmers',
  8: 'Roku Nana',
};

// player id -> [ign, teamId, jersey]
export const PLAYERS = {
  1: ['aus#MTB', 1, 1], 2: ['xixi#0830', 1, 2], 3: ['carp#444', 1, 3], 4: ['Sleepy Femboy#rawr', 1, 4], 5: ['madge#koow', 1, 5],
  6: ['im still shining#almor', 2, 1], 7: ['Coach Lobster#Coach', 2, 2], 8: ['playn with toes#toes', 2, 3], 9: ['Sa1ty#123', 2, 4], 10: ['skytookie#sub', 2, 5],
  11: ['kaleiydo#scope', 3, 1], 12: ['SeijinTea#TTV', 3, 2], 13: ['sandtose#9610', 3, 3], 14: ['ML revrzd#gato', 3, 4], 15: ['josepi#jac', 3, 5], 16: ['vicesippy#BIGT', 3, 6],
  17: ['Tekkni#Shoot', 4, 1], 18: ['Zalphine#Snort', 4, 2], 19: ['BangBang#Panda', 4, 3], 20: ['thecanadiancooki#SKZ', 4, 4], 21: ['QOR ttinybones#AAAAA', 4, 5], 22: ['Jane Doe#ChitZ', 4, 6],
  23: ['QOR hamouduh#Syria', 5, 1], 24: ['singularity#kiwi', 5, 2], 25: ['olivegrovepapi#ttv', 5, 3], 26: ['DoctorMoesy#TTV', 5, 4], 27: ['m0ld#dems', 5, 5], 28: ['navi#look', 5, 6], 29: ['shawarma#xtoum', 5, 7],
  30: ['ekittenuwuboy67#lumei', 6, 1], 31: ['happycamper#1018', 6, 2], 32: ['laki#plays', 6, 3], 33: ['juicebox#kitty', 6, 4], 34: ['silly penguin13#dae', 6, 5],
  35: ['oni#AURAA', 7, 1], 36: ['Colt#GGTTV', 7, 2], 37: ['Rocke#813', 7, 3], 38: ['Kairu#1473', 7, 4], 39: ['icarus 407#VGS47', 7, 5], 40: ['sig too clean#ttv', 7, 6], 41: ['chuwy#kiki', 7, 7],
  42: ['JareBear#TTV', 8, 1], 43: ['dberg#omen', 8, 2], 44: ['versi#nat', 8, 3], 45: ['lil chicken wrap#ranch', 8, 4], 46: ['BIG PT#OTOWN', 8, 5],
};

// Constellation glyphs: pts in a 40x40 box, edges as index chains, gold = index
export const TOURNAMENTS = [
  {
    code: 'SS', name: 'MTB Summer Skirmish', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'live', prize: '4,000',
    dates: 'AUG 20–23 2026', month: 'AUG 2026', size: '4 TEAMS',
    champion: null, note: 'Final · Sahurs vs Harmony',
    glyph: { pts: [[8, 30], [16, 10], [23, 20], [32, 6]], gold: 3 },
  },
  {
    code: 'FI', name: 'MTB Fall Invitational', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'upcoming', prize: '3,000',
    dates: 'SEP 12–13 2026', month: 'SEP 2026', size: '4 TEAMS',
    champion: null, note: '4 teams registered',
    glyph: { pts: [[8, 32], [18, 24], [24, 14], [34, 6]], gold: 3 },
  },
  {
    code: 'CC', name: 'Creator Cup', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'completed', prize: '5,000',
    dates: 'MAR 14–16 2026', month: 'MAR 2026', size: '8 TEAMS',
    champion: "Triple T's Sahurs",
    championMeta: '3–0 IN BRACKET · 39 ROUNDS WON',
    championPrize: '3,000 FIRST PRIZE · PAID',
    glyph: { pts: [[8, 10], [12, 24], [20, 34], [28, 24], [32, 10]], gold: 2 },
  },
  {
    code: 'WC', name: 'MTB Winter Clash', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'completed', prize: '3,000',
    dates: 'APR 11–12 2026', month: 'APR 2026', size: '4 TEAMS',
    champion: 'The Almond Joys',
    championMeta: '2–0 IN BRACKET · 26 ROUNDS WON',
    championPrize: '2,000 FIRST PRIZE · DUE',
    glyph: { pts: [[6, 10], [14, 26], [20, 14], [26, 26], [34, 10]], gold: 2 },
  },
  {
    code: 'TF', name: 'MTB TFT Open', game: 'Teamfight Tactics', format: 'points',
    formatLabel: 'POINTS BY PLACEMENT', status: 'completed', prize: '2,000',
    dates: 'MAY 02–03 2026', month: 'MAY 2026', size: '8 PLAYERS',
    champion: 'Setsuko#TFT',
    glyph: { pts: [[20, 6], [32, 20], [20, 34], [8, 20], [20, 20]], gold: 4, closed: true },
  },
  {
    code: 'RL', name: 'Rocket League 1v1 Showdown', game: 'Rocket League', format: 'series',
    formatLabel: 'BEST OF 3', status: 'completed', prize: '1,000',
    dates: 'MAY 09 2026', month: 'MAY 2026', size: '2 PLAYERS',
    champion: 'Jstn1v1#RL',
    championMeta: '2–1 IN THE SERIES',
    championPrize: '1,000 FIRST PRIZE · PAID',
    glyph: { pts: [[8, 20], [32, 20]], gold: 0 },
  },
];

// Matches. sides: [[name, score], [name, score]] with winner first, or null when
// not yet played. stats: [playerId, kills, deaths, assists, score].
export const MATCHES = [
  // Creator Cup
  { id: 1, t: 'CC', round: 1, slot: 1, time: 'MAR 14 · 12:00', sides: [[1, 13], [8, 7]],
    stats: [[1, 12, 8, 11, 178], [2, 25, 15, 6, 195], [3, 20, 10, 11, 212], [4, 15, 17, 6, 229], [5, 10, 12, 11, 246], [42, 23, 19, 6, 275], [43, 18, 14, 11, 292], [44, 13, 9, 6, 309], [45, 26, 16, 11, 326], [46, 21, 11, 6, 343]] },
  { id: 2, t: 'CC', round: 1, slot: 2, time: 'MAR 14 · 13:30', sides: [[4, 13], [5, 10]],
    stats: [[17, 11, 17, 4, 261], [18, 24, 12, 9, 278], [19, 19, 19, 4, 295], [20, 14, 14, 9, 312], [21, 27, 9, 4, 329], [23, 17, 11, 4, 163], [24, 12, 18, 9, 180], [25, 25, 13, 4, 197], [26, 20, 8, 9, 214], [27, 15, 15, 4, 231]] },
  { id: 3, t: 'CC', round: 1, slot: 3, time: 'MAR 14 · 15:00', sides: [[3, 13], [6, 4]],
    stats: [[11, 12, 16, 7, 170], [12, 25, 11, 12, 187], [13, 20, 18, 7, 204], [14, 15, 13, 12, 221], [15, 10, 8, 7, 238], [30, 25, 17, 12, 293], [31, 20, 12, 7, 310], [32, 15, 19, 12, 327], [33, 10, 14, 7, 344], [34, 23, 9, 12, 161]] },
  { id: 4, t: 'CC', round: 1, slot: 4, time: 'MAR 14 · 16:30', sides: [[2, 13], [7, 9]],
    stats: [[6, 26, 10, 5, 296], [7, 21, 17, 10, 313], [8, 16, 12, 5, 330], [9, 11, 19, 10, 347], [10, 24, 14, 5, 164], [35, 25, 9, 10, 189], [36, 20, 16, 5, 206], [37, 15, 11, 10, 223], [38, 10, 18, 5, 240], [39, 23, 13, 10, 257]] },
  { id: 5, t: 'CC', round: 2, slot: 1, time: 'MAR 15 · 12:00', sides: [[1, 13], [4, 11]],
    stats: [[1, 22, 16, 3, 222], [2, 17, 11, 8, 239], [3, 12, 18, 3, 256], [4, 25, 13, 8, 273], [5, 20, 8, 3, 290], [17, 14, 8, 3, 294], [18, 27, 15, 8, 311], [19, 22, 10, 3, 328], [20, 17, 17, 8, 345], [21, 12, 12, 3, 162]] },
  { id: 6, t: 'CC', round: 2, slot: 2, time: 'MAR 15 · 14:00', sides: [[2, 13], [3, 11]],
    stats: [[11, 15, 19, 6, 203], [12, 10, 14, 11, 220], [13, 23, 9, 6, 237], [14, 18, 16, 11, 254], [15, 13, 11, 6, 271], [6, 22, 8, 11, 318], [7, 17, 15, 6, 335], [8, 12, 10, 11, 152], [9, 25, 17, 6, 169], [10, 20, 12, 11, 186]] },
  { id: 7, t: 'CC', round: 3, slot: 1, time: 'MAR 16 · 15:00', sides: [[1, 13], [2, 8]],
    stats: [[1, 18, 14, 9, 244], [2, 13, 9, 4, 261], [3, 26, 16, 9, 278], [4, 21, 11, 4, 295], [5, 16, 18, 9, 312], [6, 11, 13, 4, 329], [7, 24, 8, 9, 346], [8, 19, 15, 4, 163], [9, 14, 10, 9, 180], [10, 27, 17, 4, 197]] },

  // MTB Winter Clash
  { id: 8, t: 'WC', round: 1, slot: 1, time: 'APR 11 · 13:00', sides: [[1, 13], [4, 6]],
    stats: [[1, 25, 19, 12, 255], [2, 20, 14, 7, 272], [3, 15, 9, 12, 289], [4, 10, 16, 7, 306], [5, 23, 11, 12, 323], [17, 17, 11, 12, 327], [18, 12, 18, 7, 344], [19, 25, 13, 12, 161], [20, 20, 8, 7, 178], [21, 15, 15, 12, 195]] },
  { id: 9, t: 'WC', round: 1, slot: 2, time: 'APR 11 · 15:00', sides: [[2, 13], [3, 9]],
    stats: [[6, 25, 11, 10, 151], [7, 20, 18, 5, 168], [8, 15, 13, 10, 185], [9, 10, 8, 5, 202], [10, 23, 15, 10, 219], [11, 18, 10, 5, 236], [12, 13, 17, 10, 253], [13, 26, 12, 5, 270], [14, 21, 19, 10, 287], [15, 16, 14, 5, 304]] },
  { id: 10, t: 'WC', round: 2, slot: 1, time: 'APR 12 · 15:00', sides: [[2, 13], [1, 9]],
    stats: [[1, 21, 17, 8, 277], [2, 16, 12, 3, 294], [3, 11, 19, 8, 311], [4, 24, 14, 3, 328], [5, 19, 9, 8, 345], [6, 14, 16, 3, 162], [7, 27, 11, 8, 179], [8, 22, 18, 3, 196], [9, 17, 13, 8, 213], [10, 12, 8, 3, 230]] },

  // MTB TFT Open lobbies: sides null, lobby holds [ign, placement, points]
  { id: 11, t: 'TF', round: 1, slot: 1, time: 'MAY 02 · 18:00',
    lobby: [['Setsuko#TFT', 1, 8], ['kiyoomi#EUW', 2, 7], ['Rerolla#NA1', 3, 6], ['Augment#0001', 4, 5], ['TinyLegend#tft', 5, 4], ['Carousel#spin', 6, 3], ['Fortune#4win', 7, 2], ['HyperRoll#top4', 8, 1]] },
  { id: 12, t: 'TF', round: 2, slot: 1, time: 'MAY 03 · 18:00',
    lobby: [['Rerolla#NA1', 1, 8], ['Setsuko#TFT', 2, 7], ['TinyLegend#tft', 3, 6], ['kiyoomi#EUW', 4, 5], ['HyperRoll#top4', 5, 4], ['Augment#0001', 6, 3], ['Carousel#spin', 7, 2], ['Fortune#4win', 8, 1]] },

  // Rocket League 1v1 series: solo sides carry names directly
  { id: 13, t: 'RL', round: 1, slot: 1, time: 'MAY 09 · 12:00', solo: [['Jstn1v1#RL', 4], ['Firstkiller#duel', 2]] },
  { id: 14, t: 'RL', round: 2, slot: 1, time: 'MAY 09 · 12:30', solo: [['Firstkiller#duel', 5], ['Jstn1v1#RL', 2]] },
  { id: 15, t: 'RL', round: 3, slot: 1, time: 'MAY 09 · 13:00', solo: [['Jstn1v1#RL', 3], ['Firstkiller#duel', 1]] },

  // MTB Summer Skirmish (live)
  { id: 16, t: 'SS', round: 1, slot: 1, time: 'AUG 20 · 18:00', sides: [[1, 13], [7, 9]],
    stats: [[1, 24, 12, 9, 318], [2, 19, 14, 7, 286], [3, 27, 10, 5, 341], [4, 16, 13, 12, 264], [5, 21, 11, 8, 302], [35, 18, 15, 6, 247], [36, 14, 19, 10, 223], [37, 22, 16, 4, 276], [38, 11, 17, 9, 201], [39, 17, 18, 7, 239]] },
  { id: 17, t: 'SS', round: 1, slot: 2, time: 'AUG 21 · 18:00', sides: [[4, 13], [2, 11]],
    stats: [[17, 23, 11, 8, 316], [18, 18, 13, 11, 285], [19, 26, 9, 6, 348], [20, 15, 16, 12, 259], [21, 20, 12, 7, 299], [6, 16, 18, 5, 231], [7, 21, 14, 8, 271], [8, 12, 19, 10, 205], [9, 19, 15, 4, 253], [10, 13, 17, 9, 218]] },
  { id: 18, t: 'SS', round: 2, slot: 1, time: 'AUG 23 · 18:00', sides: null, hint: 'Sahurs vs Harmony' },

  // MTB Fall Invitational (upcoming, field seeded, pairings TBD)
  { id: 19, t: 'FI', round: 1, slot: 1, time: 'SEP 12 · 15:00', sides: null },
  { id: 20, t: 'FI', round: 1, slot: 2, time: 'SEP 12 · 18:00', sides: null },
  { id: 21, t: 'FI', round: 2, slot: 1, time: 'SEP 13 · 17:00', sides: null },
];

// TFT classification: [pos, ign, l1, l2, pts, gap, int, note]
export const TFT_STANDINGS = [
  [1, 'Setsuko#TFT', 1, 2, 15, null, null, 'CHAMPION'],
  [2, 'Rerolla#NA1', 3, 1, 14, -1, -1, null],
  [3, 'kiyoomi#EUW', 2, 4, 12, -3, -2, null],
  [4, 'TinyLegend#tft', 5, 3, 10, -5, -2, null],
  [5, 'Augment#0001', 4, 6, 8, -7, -2, null],
  [6, 'HyperRoll#top4', 8, 5, 5, -10, -3, 'TIE ON PTS · BEST FINISH'],
  [7, 'Carousel#spin', 6, 7, 5, -10, 0, null],
  [8, 'Fortune#4win', 7, 8, 3, -12, -2, null],
];

// Admin data, mirrored from Transactions / Payments / Membership seed rows.
export const ADMIN = {
  // [event, revenue, expense]
  financials: [
    ['Creator Cup', 9500, 8200],
    ['MTB Winter Clash', 2500, 3000],
    ['MTB TFT Open', 3500, 2000],
    ['Rocket League 1v1 Showdown', 900, 1000],
    ['MTB Summer Skirmish', 3600, 1200],
    ['MTB Fall Invitational', 1500, 0],
  ],
  // [payeeType, payee, event, amount]
  outstanding: [
    ['team', 'The Almond Joys', 'MTB Winter Clash', 2000],
    ['team', 'Elements of Harmony', 'MTB Winter Clash', 1000],
    ['player', 'Rerolla#NA1', 'MTB TFT Open', 800],
    ['staff', 'Head Caster', 'MTB Summer Skirmish', 450],
    ['staff', 'Lead Moderator', 'Creator Cup', 300],
  ],
  // [name, email, role, since]
  members: [
    ['Tournament Admin', 'admin@mtbevents.gg', 'admin', 'JAN 2024'],
    ['Head Caster', 'caster@mtbevents.gg', 'caster', 'FEB 2024'],
    ['Lead Moderator', 'mod@mtbevents.gg', 'moderator', 'FEB 2024'],
    ['Broadcast Producer', 'producer@mtbevents.gg', 'producer', 'MAR 2024'],
  ],
};

// Match-day operations (StaffMatches + CreatorMatches seed rows), by match id.
export const OPS = {
  5: { creators: ['revrzd'] },
  7: { staff: ['Head Caster · caster', 'Lead Moderator · moderator'], creators: ['revrzd', 'almondfps'] },
  10: { staff: ['Head Caster · caster'] },
  16: { staff: ['Head Caster · caster', 'Lead Moderator · moderator'], creators: ['revrzd'] },
  17: { staff: ['Head Caster · caster'], creators: ['revrzd'] },
};

// Deliverables (staff tracker): [party, partyType, event, description, type, due, status, clicks]
export const DELIVERABLES = [
  ['Red Bull', 'sponsor', 'Creator Cup', 'Logo on stream overlay', 'branding', 'MAR 16 2026', 'fulfilled', 1240],
  ['Red Bull', 'sponsor', 'Creator Cup', 'Mid-event sponsor segment', 'activation', 'MAR 15 2026', 'fulfilled', 860],
  ['Logitech', 'sponsor', 'Creator Cup', 'Product giveaway', 'activation', 'MAR 16 2026', 'fulfilled', 2100],
  ['Logitech', 'sponsor', 'Creator Cup', 'Banner ad on broadcast', 'branding', 'MAR 16 2026', 'pending', 0],
  ['revrzd', 'creator', 'Creator Cup', '2 promotional videos', 'content', 'MAR 10 2026', 'pending', 3200],
  ['Discord', 'sponsor', 'MTB Winter Clash', 'Discord server integration', 'activation', 'APR 12 2026', 'fulfilled', 940],
  ['Discord', 'sponsor', 'MTB Summer Skirmish', 'Sponsored stream overlay', 'branding', 'AUG 23 2026', 'fulfilled', 1580],
  ['Discord', 'sponsor', 'MTB Summer Skirmish', 'Community Discord event', 'activation', 'AUG 22 2026', 'pending', 0],
];

// Data-quality reports (v_registration_violations, v_match_integrity).
export const INTEGRITY = {
  violations: [],
  matchIssues: [
    ['SS-F', 'MTB Summer Skirmish', 'AUG 23 · 18:00', 'no participants recorded'],
    ['FI-SF1', 'MTB Fall Invitational', 'SEP 12 · 15:00', 'no participants recorded'],
    ['FI-SF2', 'MTB Fall Invitational', 'SEP 12 · 18:00', 'no participants recorded'],
    ['FI-F', 'MTB Fall Invitational', 'SEP 13 · 17:00', 'no participants recorded'],
  ],
  cleanMatches: 17,
};

// Role-tier portals (v_my_profile, v_my_team_payouts, v_my_contract_deliverables,
// v_my_creator_assignments), fixed to the demo identities.
export const PORTAL = {
  player: {
    ign: 'aus#MTB', country: 'USA', born: 'FEB 1999',
    team: "Triple T's Sahurs", jersey: 1, joined: 'FEB 20 2026', salary: '1,250',
  },
  org: {
    name: 'QOR', region: 'NA', founded: 'JUN 2021', teams: ['Elements of Harmony', 'MENAces'],
    // [team, event, amount, status, date]
    payouts: [
      ['Elements of Harmony', 'Creator Cup', '500', 'PAID', 'MAR 18 2026'],
      ['Elements of Harmony', 'MTB Winter Clash', '1,000', 'PENDING', '–'],
      ['MENAces', '–', '–', 'NO PAYOUT RECORDED', '–'],
    ],
  },
  sponsor: {
    name: 'Red Bull', contact: 'Maria Lopez',
    contract: { event: 'Creator Cup', value: '5,000', window: 'JAN 01 – MAR 16 2026' },
    // [description, type, due, status, clicks]
    deliverables: [
      ['Logo on stream overlay', 'branding', 'MAR 16 2026', 'fulfilled', 1240],
      ['Mid-event sponsor segment', 'activation', 'MAR 15 2026', 'fulfilled', 860],
    ],
  },
  creator: {
    name: 'revrzd', link: 'twitch.tv/revrzd',
    // [event, role, rate, status, matchesStreamed]
    assignments: [
      ['Creator Cup', 'streamer', '500', 'active', 2],
      ['MTB Summer Skirmish', 'streamer', '450', 'active', 2],
    ],
  },
};

export function rosterOf(teamId) {
  return Object.entries(PLAYERS)
    .filter(([, p]) => p[1] === teamId)
    .map(([id, p]) => ({ id: Number(id), ign: p[0], jersey: p[2], salary: (p[2] <= 5 ? 1200 : 600) + teamId * 50 }))
    .sort((a, b) => a.jersey - b.jersey);
}

export function tournament(code) {
  return TOURNAMENTS.find((t) => t.code === code);
}

export function matchesFor(code) {
  return MATCHES.filter((m) => m.t === code);
}

export function match(id) {
  return MATCHES.find((m) => m.id === Number(id));
}
