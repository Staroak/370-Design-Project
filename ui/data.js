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

export const TEAM_META = {
  1: { captain: 'milkteaboards', founded: 'OCT 08 2025', region: 'NA' },
  2: { captain: 'almondfps', founded: 'OCT 15 2025', region: 'NA' },
  3: { captain: 'kaleiydo', founded: 'OCT 22 2025', region: 'NA' },
  4: { captain: 'ttinybones', founded: 'OCT 29 2025', region: 'NA' },
  5: { captain: 'hamouduh', founded: 'NOV 05 2025', region: 'NA' },
  6: { captain: 'daeunnie', founded: 'NOV 12 2025', region: 'NA' },
  7: { captain: 'oniaura', founded: 'NOV 19 2025', region: 'NA' },
  8: { captain: 'jarebeartv', founded: 'NOV 26 2025', region: 'NA' },
};

const SEED_TEAM_NAMES = { ...TEAMS };

export const CREATORS = [
  { id: 1, name: 'revrzd', twitch: 'twitch.tv/revrzd', instagram: '', twitter: '', pic: '' },
  { id: 2, name: 'almondfps', twitch: '', instagram: 'instagram.com/almondfps', twitter: '', pic: '' },
  { id: 3, name: 'JareBear', twitch: '', instagram: '', twitter: 'twitter.com/jarebeartv', pic: '' },
  { id: 4, name: 'nova_flux', twitch: 'twitch.tv/nova_flux', instagram: 'instagram.com/nova_flux', twitter: '', pic: '' },
  { id: 5, name: 'PixelPerry', twitch: '', instagram: 'instagram.com/pixelperry', twitter: '', pic: '' },
  { id: 6, name: 'GhostOfLobbyB', twitch: '', instagram: '', twitter: 'twitter.com/ghostoflobbyb', pic: '' },
  { id: 7, name: 'QueenQuince', twitch: 'twitch.tv/queenquince', instagram: '', twitter: '', pic: '' },
  { id: 8, name: 'mothlamp', twitch: '', instagram: 'instagram.com/mothlamp', twitter: 'twitter.com/mothlamp', pic: '' },
  { id: 9, name: 'RiftRaccoon', twitch: '', instagram: '', twitter: 'twitter.com/riftraccoon', pic: '' },
  { id: 10, name: 'saltcircuit', twitch: 'twitch.tv/saltcircuit', instagram: '', twitter: '', pic: '' },
  { id: 11, name: 'DrDelusion', twitch: '', instagram: 'instagram.com/drdelusion', twitter: '', pic: '' },
  { id: 12, name: 'CozyKumo', twitch: 'twitch.tv/cozykumo', instagram: '', twitter: 'twitter.com/cozykumo', pic: '' },
  { id: 13, name: 'blinkfrog', twitch: 'twitch.tv/blinkfrog', instagram: '', twitter: '', pic: '' },
  { id: 14, name: 'TiltProof_Tia', twitch: '', instagram: 'instagram.com/tiltproof_tia', twitter: '', pic: '' },
  { id: 15, name: 'VandalVera', twitch: '', instagram: '', twitter: 'twitter.com/vandalvera', pic: '' },
  { id: 16, name: 'LowTierLuke', twitch: 'twitch.tv/lowtierluke', instagram: 'instagram.com/lowtierluke', twitter: '', pic: '' },
  { id: 17, name: 'MangoMouse', twitch: '', instagram: 'instagram.com/mangomouse', twitter: '', pic: '' },
  { id: 18, name: 'aim_gremlin', twitch: '', instagram: '', twitter: 'twitter.com/aim_gremlin', pic: '' },
  { id: 19, name: 'SleeplessSachi', twitch: 'twitch.tv/sleeplesssachi', instagram: '', twitter: '', pic: '' },
  { id: 20, name: 'TurboTurnip', twitch: '', instagram: 'instagram.com/turboturnip', twitter: 'twitter.com/turboturnip', pic: '' },
  { id: 21, name: 'hexadecimal_hana', twitch: '', instagram: '', twitter: 'twitter.com/hexadecimal_hana', pic: '' },
  { id: 22, name: 'ClutchCactus', twitch: 'twitch.tv/clutchcactus', instagram: '', twitter: '', pic: '' },
  { id: 23, name: 'PeachPetrichor', twitch: '', instagram: 'instagram.com/peachpetrichor', twitter: '', pic: '' },
  { id: 24, name: 'wafflewizard', twitch: 'twitch.tv/wafflewizard', instagram: '', twitter: 'twitter.com/wafflewizard', pic: '' },
  { id: 25, name: 'MidnightMori', twitch: 'twitch.tv/midnightmori', instagram: '', twitter: '', pic: '' },
  { id: 26, name: 'opal_owl', twitch: '', instagram: 'instagram.com/opal_owl', twitter: '', pic: '' },
  { id: 27, name: 'ReloadRhea', twitch: '', instagram: '', twitter: 'twitter.com/reloadrhea', pic: '' },
  { id: 28, name: 'StaticStorm', twitch: 'twitch.tv/staticstorm', instagram: 'instagram.com/staticstorm', twitter: '', pic: '' },
  { id: 29, name: 'chaikappa', twitch: '', instagram: 'instagram.com/chaikappa', twitter: '', pic: '' },
  { id: 30, name: 'NoScopeNori', twitch: '', instagram: '', twitter: 'twitter.com/noscopenori', pic: '' },
  { id: 31, name: 'VelvetViper', twitch: 'twitch.tv/velvetviper', instagram: '', twitter: '', pic: '' },
  { id: 32, name: 'brickbybrick', twitch: '', instagram: 'instagram.com/brickbybrick', twitter: 'twitter.com/brickbybrick', pic: '' },
  { id: 33, name: 'LagSpikeLarry', twitch: '', instagram: '', twitter: 'twitter.com/lagspikelarry', pic: '' },
  { id: 34, name: 'CtrlAltDefeat', twitch: 'twitch.tv/ctrlaltdefeat', instagram: '', twitter: '', pic: '' },
  { id: 35, name: 'moon_moth_mia', twitch: '', instagram: 'instagram.com/moon_moth_mia', twitter: '', pic: '' },
  { id: 36, name: 'RoundhouseRiko', twitch: 'twitch.tv/roundhouseriko', instagram: '', twitter: 'twitter.com/roundhouseriko', pic: '' },
  { id: 37, name: 'sagemain_sam', twitch: 'twitch.tv/sagemain_sam', instagram: '', twitter: '', pic: '' },
  { id: 38, name: 'DumpsterDiveDee', twitch: '', instagram: 'instagram.com/dumpsterdivedee', twitter: '', pic: '' },
  { id: 39, name: 'frostbyte_fi', twitch: '', instagram: '', twitter: 'twitter.com/frostbyte_fi', pic: '' },
  { id: 40, name: 'EcoRoundEcho', twitch: 'twitch.tv/ecoroundecho', instagram: 'instagram.com/ecoroundecho', twitter: '', pic: '' },
  { id: 41, name: 'plinko_pilot', twitch: '', instagram: 'instagram.com/plinko_pilot', twitter: '', pic: '' },
  { id: 42, name: 'WardenWisp', twitch: '', instagram: '', twitter: 'twitter.com/wardenwisp', pic: '' },
  { id: 43, name: 'tofu_tempest', twitch: 'twitch.tv/tofu_tempest', instagram: '', twitter: '', pic: '' },
  { id: 44, name: 'GlimmerGoat', twitch: '', instagram: 'instagram.com/glimmergoat', twitter: 'twitter.com/glimmergoat', pic: '' },
  { id: 45, name: 'ProxyPigeon', twitch: '', instagram: '', twitter: 'twitter.com/proxypigeon', pic: '' },
  { id: 46, name: 'slowmo_sloth', twitch: 'twitch.tv/slowmo_sloth', instagram: '', twitter: '', pic: '' },
  { id: 47, name: 'KDA_Karma', twitch: '', instagram: 'instagram.com/kda_karma', twitter: '', pic: '' },
  { id: 48, name: 'NebulaNessa', twitch: 'twitch.tv/nebulanessa', instagram: '', twitter: 'twitter.com/nebulanessa', pic: '' },
  { id: 49, name: 'quietquasar', twitch: 'twitch.tv/quietquasar', instagram: '', twitter: '', pic: '' },
  { id: 50, name: 'BaronBaited', twitch: '', instagram: 'instagram.com/baronbaited', twitter: '', pic: '' },
  { id: 51, name: 'static_shanty', twitch: '', instagram: '', twitter: 'twitter.com/static_shanty', pic: '' },
  { id: 52, name: 'OrbitalOtter', twitch: 'twitch.tv/orbitalotter', instagram: 'instagram.com/orbitalotter', twitter: '', pic: '' },
];

export const CREATOR_ASSIGNMENTS = [
  { creatorId: 1, code: 'CC', role: 'streamer', rate: 500, status: 'active' },
  { creatorId: 2, code: 'CC', role: 'host', rate: 400, status: 'active' },
  { creatorId: 3, code: 'WC', role: 'streamer', rate: 350, status: 'active' },
  { creatorId: 1, code: 'SS', role: 'streamer', rate: 450, status: 'active' },
  { creatorId: 5, code: 'CC', role: 'caster', rate: 250, status: 'active' },
  { creatorId: 9, code: 'SS', role: 'observer', rate: 150, status: 'active' },
  { creatorId: 12, code: 'WC', role: 'host', rate: 300, status: 'active' },
  { creatorId: 15, code: 'TF', role: 'streamer', rate: 400, status: 'active' },
  { creatorId: 18, code: 'RL', role: 'caster', rate: 200, status: 'active' },
  { creatorId: 22, code: 'SS', role: 'streamer', rate: 350, status: 'active' },
  { creatorId: 27, code: 'FI', role: 'streamer', rate: 300, status: 'active' },
  { creatorId: 31, code: 'CC', role: 'observer', rate: 150, status: 'active' },
  { creatorId: 36, code: 'TF', role: 'host', rate: 250, status: 'active' },
  { creatorId: 44, code: 'FI', role: 'caster', rate: 275, status: 'active' },
];

export const GAMES = {
  valorant: { name: 'Valorant', label: 'VALORANT', codes: ['CC', 'WC', 'SS', 'FI'] },
  tft: { name: 'Teamfight Tactics', label: 'TEAMFIGHT TACTICS', codes: ['TF'] },
  rl: { name: 'Rocket League', label: 'ROCKET LEAGUE', codes: ['RL'] },
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
  47: ['Setsuko#TFT', 0, 0], 48: ['kiyoomi#EUW', 0, 0], 49: ['Rerolla#NA1', 0, 0], 50: ['Augment#0001', 0, 0], 51: ['TinyLegend#tft', 0, 0],
  52: ['Carousel#spin', 0, 0], 53: ['Fortune#4win', 0, 0], 54: ['HyperRoll#top4', 0, 0], 55: ['Jstn1v1#RL', 0, 0], 56: ['Firstkiller#duel', 0, 0],
};

const SEED_IGNS = Object.fromEntries(Object.entries(PLAYERS).map(([id, p]) => [id, p[0]]));

// Constellation glyphs: pts in a 40x40 box, edges as index chains, gold = index
export const TOURNAMENTS = [
  {
    code: 'SS', name: 'MTB Summer Skirmish', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'live', prize: '4,000',
    dates: 'AUG 20–23 2026', month: 'AUG 2026', size: '4 TEAMS',
    field: [1, 2, 4, 7],
    champion: null, note: 'Final · Sahurs vs Harmony',
    glyph: { pts: [[8, 30], [16, 10], [23, 20], [32, 6]], gold: 3 },
  },
  {
    code: 'FI', name: 'MTB Fall Invitational', game: 'Valorant', format: 'elim',
    formatLabel: 'SINGLE ELIMINATION', status: 'upcoming', prize: '3,000',
    dates: 'SEP 12–13 2026', month: 'SEP 2026', size: '4 TEAMS',
    field: [3, 5, 6, 8],
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

export const NEW_GLYPHS = [
  { pts: [[7, 28], [14, 12], [25, 9], [33, 25]], gold: 2 },
  { pts: [[9, 9], [17, 26], [26, 15], [32, 32]], gold: 1 },
  { pts: [[6, 20], [15, 7], [22, 18], [30, 10], [34, 29]], gold: 3 },
  { pts: [[8, 31], [13, 15], [21, 25], [28, 8], [35, 21]], gold: 0 },
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
    ['GRAND FINAL', 'MTB Summer Skirmish', 'AUG 23 · 18:00', 'no participants recorded'],
    ['SEMIFINAL 1', 'MTB Fall Invitational', 'SEP 12 · 15:00', 'no participants recorded'],
    ['SEMIFINAL 2', 'MTB Fall Invitational', 'SEP 12 · 18:00', 'no participants recorded'],
    ['GRAND FINAL', 'MTB Fall Invitational', 'SEP 13 · 17:00', 'no participants recorded'],
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

const STORE_KEY = 'star-tournaments-demo-v2';

function emptyStore() {
  return {
    results: {},
    created: [],
    creators: null,
    creatorAssignments: null,
    playerCheckins: {},
    streams: {},
    eventEdits: {},
    matchTimes: {},
    teamEdits: {},
    playerEdits: {},
  };
}

function cleanStore(value) {
  return {
    results: value && value.results && typeof value.results === 'object' ? value.results : {},
    created: Array.isArray(value && value.created) ? value.created : [],
    creators: Array.isArray(value && value.creators) ? value.creators : null,
    creatorAssignments: Array.isArray(value && value.creatorAssignments) ? value.creatorAssignments : null,
    playerCheckins: value && value.playerCheckins && typeof value.playerCheckins === 'object' ? value.playerCheckins : {},
    streams: value && value.streams && typeof value.streams === 'object' ? value.streams : {},
    eventEdits: value && value.eventEdits && typeof value.eventEdits === 'object' ? value.eventEdits : {},
    matchTimes: value && value.matchTimes && typeof value.matchTimes === 'object' ? value.matchTimes : {},
    teamEdits: value && value.teamEdits && typeof value.teamEdits === 'object' ? value.teamEdits : {},
    playerEdits: value && value.playerEdits && typeof value.playerEdits === 'object' ? value.playerEdits : {},
  };
}

function loadStore() {
  try {
    const raw = globalThis.localStorage && globalThis.localStorage.getItem(STORE_KEY);
    return raw ? cleanStore(JSON.parse(raw)) : emptyStore();
  } catch {
    return emptyStore();
  }
}

let store = loadStore();
const playerCheckins = store.playerCheckins;

function saveStore() {
  try {
    if (globalThis.localStorage) globalThis.localStorage.setItem(STORE_KEY, JSON.stringify(store));
  } catch {
    // Storage can be blocked; the mutable arrays still carry this session.
  }
}

function syncCompetitorName(oldName, newName) {
  if (!oldName || !newName || oldName === newName) return;
  TOURNAMENTS.forEach((t) => {
    if (t.champion === oldName) t.champion = newName;
  });
  MATCHES.forEach((m) => {
    if (m.lobby) {
      m.lobby.forEach((row) => {
        if (row[0] === oldName) row[0] = newName;
      });
    }
    if (m.solo) {
      m.solo.forEach((side) => {
        if (side[0] === oldName) side[0] = newName;
      });
    }
  });
}

function hasAngleText(values) {
  return values.some((value) => /[<>]/.test(String(value || '')));
}

export function storeSnapshot() {
  return store;
}

export function tftStandings(code = 'TF') {
  const event = TOURNAMENTS.find((t) => t.code === code);
  const rounds = MATCHES
    .filter((m) => m.t === code && m.lobby)
    .slice()
    .sort((a, b) => a.round - b.round);
  const players = new Map();

  rounds.forEach((m, roundIndex) => {
    m.lobby.forEach(([ign, placement, points]) => {
      const row = players.get(ign) || { ign, placements: [], points: 0 };
      row.placements[roundIndex] = placement;
      row.points += Number(points) || 0;
      players.set(ign, row);
    });
  });

  const pidForIgn = (ign) => {
    const hit = Object.entries(PLAYERS).find(([, p]) => p[0] === ign);
    return hit ? Number(hit[0]) : null;
  };
  const bestFinish = (row) => Math.min(...row.placements.filter((placement) => placement != null));
  const sorted = [...players.values()].sort((a, b) => {
    const pointOrder = b.points - a.points;
    if (pointOrder) return pointOrder;
    const finishOrder = bestFinish(a) - bestFinish(b);
    if (finishOrder) return finishOrder;
    return a.ign.localeCompare(b.ign, undefined, { sensitivity: 'base' });
  });
  const leaderPts = sorted.length ? sorted[0].points : 0;

  return sorted.map((row, index) => {
    const previous = sorted[index - 1];
    const next = sorted[index + 1];
    const note = index === 0 && event && event.status === 'completed'
      ? 'CHAMPION'
      : next && next.points === row.points
        ? 'TIE ON PTS · BEST FINISH'
        : null;
    return [
      index + 1,
      row.ign,
      row.placements[0] ?? null,
      row.placements[1] ?? null,
      row.points,
      index === 0 ? null : row.points - leaderPts,
      index === 0 ? null : row.points - previous.points,
      note,
      pidForIgn(row.ign),
    ];
  });
}

export function streamFor(code) {
  return String(store.streams[String(code || '').trim()] || '');
}

export function setStream(code, raw) {
  const cleanCode = String(code || '').trim();
  let channel = String(raw || '').trim();
  channel = channel.replace(/^https?:\/\//i, '');
  channel = channel.replace(/^www\./i, '');
  channel = channel.replace(/^twitch\.tv\//i, '');
  channel = channel.split(/[?#]/)[0].replace(/\/+$/g, '').trim();

  if (!channel) {
    delete store.streams[cleanCode];
    saveStore();
    return { ok: true, channel: '' };
  }

  if (!/^[A-Za-z0-9_]{3,25}$/.test(channel)) {
    return { ok: false, error: 'not a valid twitch channel' };
  }

  store.streams[cleanCode] = channel;
  saveStore();
  return { ok: true, channel };
}

export function saveEventEdit(code, fields) {
  const cleanCode = String(code || '').trim();
  const event = TOURNAMENTS.find((t) => t.code === cleanCode);
  if (!event) return { ok: false, error: 'event not found' };

  const name = String(fields && fields.name || '').trim();
  const prizeRaw = String(fields && fields.prize || '').replace(/[,\s]/g, '');
  const prizeNumber = Number(prizeRaw);
  const dates = String(fields && fields.dates || '').trim();
  const note = String(fields && fields.note || '').trim();
  const championMeta = String(fields && fields.championMeta || '').trim();
  const championPrize = String(fields && fields.championPrize || '').trim();
  if (hasAngleText([name, dates, note, championMeta, championPrize])) return { ok: false, error: 'text cannot contain < or >' };
  if (!name) return { ok: false, error: 'name required' };
  if (!Number.isInteger(prizeNumber) || prizeNumber < 0) return { ok: false, error: 'prize must be a nonnegative number' };
  if (!dates) return { ok: false, error: 'dates required' };

  const dateTokens = dates.split(/\s+/);
  const saved = {
    name,
    prize: prizeNumber.toLocaleString('en-US'),
    dates,
    month: `${dateTokens[0]} ${dateTokens[dateTokens.length - 1]}`,
    note,
    championMeta,
    championPrize,
  };
  Object.assign(event, saved);
  store.eventEdits[cleanCode] = saved;
  saveStore();
  return { ok: true };
}

export function saveMatchTime(id, time) {
  const matchId = Number(id);
  const m = MATCHES.find((x) => x.id === matchId);
  if (!m) return { ok: false, error: 'match not found' };
  const cleanTime = String(time || '').trim();
  if (!cleanTime) return { ok: false, error: 'time required' };
  m.time = cleanTime;
  store.matchTimes[String(matchId)] = cleanTime;
  saveStore();
  return { ok: true };
}

export function saveTeamEdit(teamId, fields) {
  const id = Number(teamId);
  if (!TEAMS[id]) return { ok: false, error: 'team not found' };
  const name = String(fields && fields.name || '').trim();
  const captain = String(fields && fields.captain || '').trim();
  const founded = String(fields && fields.founded || '').trim();
  const region = String(fields && fields.region || '').trim();
  if (hasAngleText([name, captain, founded, region])) return { ok: false, error: 'text cannot contain < or >' };
  if (!name) return { ok: false, error: 'name required' };
  if (!captain || !founded || !region) return { ok: false, error: 'all fields required' };
  const lower = name.toLowerCase();
  const duplicate = Object.entries(TEAMS).some(([otherId, otherName]) => Number(otherId) !== id && String(otherName).toLowerCase() === lower);
  if (duplicate) return { ok: false, error: 'team name already in use' };

  const oldName = TEAMS[id];
  TEAMS[id] = name;
  TEAM_META[id] = { ...(TEAM_META[id] || {}), captain, founded, region };
  syncCompetitorName(oldName, name);
  store.teamEdits[String(id)] = { name, captain, founded, region };
  saveStore();
  return { ok: true };
}

export function savePlayerEdit(pid, fields) {
  const id = Number(pid);
  const player = PLAYERS[id];
  if (!player) return { ok: false, error: 'player not found' };
  const ign = String(fields && fields.ign || '').trim();
  if (hasAngleText([ign])) return { ok: false, error: 'text cannot contain < or >' };
  if (!ign) return { ok: false, error: 'ign required' };
  const lower = ign.toLowerCase();
  const duplicate = Object.entries(PLAYERS).some(([otherId, otherPlayer]) => Number(otherId) !== id && String(otherPlayer[0]).toLowerCase() === lower);
  if (duplicate) return { ok: false, error: 'ign already in use' };

  let jersey = 0;
  if (player[1] > 0) {
    jersey = Number(fields && fields.jersey);
    if (!Number.isInteger(jersey) || jersey < 1 || jersey > 99) return { ok: false, error: 'jersey must be 1 to 99' };
  }

  const oldIgn = player[0];
  player[0] = ign;
  player[2] = jersey;
  syncCompetitorName(oldIgn, ign);
  store.playerEdits[String(id)] = { ign, jersey };
  saveStore();
  return { ok: true };
}

function persistCreators() {
  store.creators = CREATORS.map((creator) => ({ ...creator }));
  store.creatorAssignments = CREATOR_ASSIGNMENTS.map((assignment) => ({ ...assignment }));
  saveStore();
}

function eventMatches(code) {
  return MATCHES.filter((m) => m.t === code);
}

function sessionLong(t, m) {
  if (t.format === 'series') return `GAME ${m.round}`;
  if (t.format === 'points') return `LOBBY ${m.round}`;
  const maxR = Math.max(...eventMatches(t.code).map((x) => x.round));
  if (m.round === maxR) return 'GRAND FINAL';
  if (m.round === maxR - 1) return `SEMIFINAL ${m.slot}`;
  return `QUARTERFINAL ${m.slot}`;
}

function feederMatches(ms, m) {
  const prev = ms.filter((x) => x.round === m.round - 1).sort((a, b) => a.slot - b.slot);
  const samePath = prev.filter((x) => Math.ceil(x.slot / 2) === m.slot);
  return samePath.length ? samePath : prev;
}

function eligibleFor(m) {
  const t = TOURNAMENTS.find((x) => x.code === m.t);
  if (!t || t.format !== 'elim' || m.sides !== null) return [];
  const ms = eventMatches(t.code);
  if (m.round === 1) {
    const used = new Set();
    ms
      .filter((x) => x.round === 1 && x.id !== m.id && x.sides)
      .forEach((x) => x.sides.forEach(([teamId]) => used.add(teamId)));
    return (t.field || []).filter((teamId) => !used.has(teamId));
  }
  const feeders = feederMatches(ms, m);
  if (!feeders.length || feeders.some((x) => !x.sides)) return [];
  return feeders.map((x) => x.sides[0][0]);
}

function reconcileElimTournaments() {
  TOURNAMENTS.filter((t) => t.format === 'elim' && eventMatches(t.code).length).forEach((t) => {
    const ms = eventMatches(t.code);
    const maxR = Math.max(...ms.map((m) => m.round));
    const final = ms.find((m) => m.round === maxR);
    const anyPlayed = ms.some((m) => m.sides);

    if (final && final.sides) {
      const edit = store.eventEdits[t.code] || {};
      t.status = 'completed';
      t.champion = TEAMS[final.sides[0][0]];
      if (!edit.championMeta && !t.championMeta) t.championMeta = 'RESULT ENTERED IN THE ADMIN CONSOLE';
      if (!edit.note) t.note = 'Champion · ' + t.champion;
    } else if (anyPlayed) {
      t.status = 'live';
      t.note = 'In progress';
    }

    ms.filter((m) => m.round > 1 && !m.sides).forEach((m) => {
      const feeders = feederMatches(ms, m);
      if (feeders.length === 2 && feeders.every((x) => x.sides)) {
        m.hint = feeders.map((x) => TEAMS[x.sides[0][0]]).join(' vs ');
      }
    });
  });
}

function applyOverrides() {
  if (Array.isArray(store.creators)) {
    CREATORS.length = 0;
    CREATORS.push(...store.creators.map((creator) => ({
      id: Number(creator.id),
      name: String(creator.name || ''),
      twitch: String(creator.twitch || ''),
      instagram: String(creator.instagram || ''),
      twitter: String(creator.twitter || ''),
      pic: String(creator.pic || ''),
    })));
  }

  if (Array.isArray(store.creatorAssignments)) {
    CREATOR_ASSIGNMENTS.length = 0;
    CREATOR_ASSIGNMENTS.push(...store.creatorAssignments.map((assignment) => ({
      creatorId: Number(assignment.creatorId),
      code: String(assignment.code || ''),
      role: String(assignment.role || ''),
      rate: Number(assignment.rate),
      status: String(assignment.status || 'active'),
    })));
  }

  store.created.forEach((entry) => {
    if (entry && entry.tournament) TOURNAMENTS.splice(1, 0, entry.tournament);
    if (entry && Array.isArray(entry.matches)) MATCHES.push(...entry.matches);
  });

  Object.entries(store.results).forEach(([id, sides]) => {
    const m = MATCHES.find((x) => x.id === Number(id));
    if (m) {
      m.sides = sides;
      delete m.hint;
    }
  });

  Object.entries(store.teamEdits).forEach(([teamId, edit]) => {
    const id = Number(teamId);
    if (!TEAMS[id] || !edit) return;
    const newName = String(edit.name || TEAMS[id]);
    TEAMS[id] = newName;
    TEAM_META[id] = {
      ...(TEAM_META[id] || {}),
      captain: String(edit.captain || (TEAM_META[id] && TEAM_META[id].captain) || ''),
      founded: String(edit.founded || (TEAM_META[id] && TEAM_META[id].founded) || ''),
      region: String(edit.region || (TEAM_META[id] && TEAM_META[id].region) || ''),
    };
    syncCompetitorName(SEED_TEAM_NAMES[id], newName);
  });

  Object.entries(store.playerEdits).forEach(([pid, edit]) => {
    const id = Number(pid);
    const player = PLAYERS[id];
    if (!player || !edit) return;
    const newIgn = String(edit.ign || player[0]);
    player[0] = newIgn;
    player[2] = Number(edit.jersey);
    syncCompetitorName(SEED_IGNS[id], newIgn);
  });

  Object.entries(store.eventEdits).forEach(([code, edit]) => {
    const event = TOURNAMENTS.find((t) => t.code === code);
    if (event && edit) Object.assign(event, edit);
  });

  Object.entries(store.matchTimes).forEach(([id, time]) => {
    const m = MATCHES.find((x) => x.id === Number(id));
    if (m) m.time = String(time || '');
  });

  reconcileElimTournaments();
}

export function openMatches() {
  return MATCHES
    .filter((m) => {
      const t = TOURNAMENTS.find((x) => x.code === m.t);
      return t && t.format === 'elim' && m.sides === null;
    })
    .map((m) => {
      const t = TOURNAMENTS.find((x) => x.code === m.t);
      return {
        id: m.id,
        code: t.code,
        label: `${t.name} · ${sessionLong(t, m)} · ${m.time}`,
        eligible: eligibleFor(m),
      };
    });
}

export function recordResult(matchId, teamA, scoreA, teamB, scoreB) {
  const m = MATCHES.find((x) => x.id === Number(matchId));
  if (!m || m.sides !== null) return { ok: false, error: 'session not open' };

  const a = Number(teamA);
  const b = Number(teamB);
  const sa = Number(scoreA);
  const sb = Number(scoreB);
  const eligible = eligibleFor(m);
  if (!eligible.length) return { ok: false, error: 'awaiting previous round' };
  if (a === b || !eligible.includes(a) || !eligible.includes(b)) return { ok: false, error: 'choose two eligible teams' };
  if (!Number.isInteger(sa) || !Number.isInteger(sb) || sa < 0 || sb < 0) return { ok: false, error: 'scores must be whole numbers' };
  if (sa === sb) return { ok: false, error: 'scores cannot tie' };

  const sides = sa > sb ? [[a, sa], [b, sb]] : [[b, sb], [a, sa]];
  m.sides = sides;
  delete m.hint;
  store.results[String(m.id)] = sides;
  saveStore();
  reconcileElimTournaments();
  return { ok: true };
}

function codeForName(name) {
  const base = (name.match(/[A-Za-z0-9]+/g) || [])
    .slice(0, 3)
    .map((word) => word[0].toUpperCase())
    .join('') || 'T';
  const used = new Set(TOURNAMENTS.map((t) => t.code));
  if (!used.has(base)) return base;
  let n = 1;
  while (used.has(`${base}${n}`)) n += 1;
  return `${base}${n}`;
}

export function createTournament({ name, prize, dates, teams }) {
  const cleanName = String(name || '').trim();
  const teamIds = (teams || []).map(Number);
  const prizeNumber = Number(prize);
  const cleanDates = String(dates || '').trim();
  if (!cleanName) return { ok: false, error: 'name required' };
  if (!Number.isFinite(prizeNumber) || prizeNumber < 500) return { ok: false, error: 'prize must be at least 500' };
  if (!cleanDates) return { ok: false, error: 'dates required' };
  if (teamIds.length !== 4 || new Set(teamIds).size !== 4 || teamIds.some((id) => !TEAMS[id])) {
    return { ok: false, error: 'choose four distinct teams' };
  }

  const code = codeForName(cleanName);
  const maxId = Math.max(...MATCHES.map((m) => m.id));
  const dateTokens = cleanDates.split(/\s+/);
  const tournament = {
    code,
    name: cleanName,
    game: 'Valorant',
    format: 'elim',
    formatLabel: 'SINGLE ELIMINATION',
    status: 'upcoming',
    prize: Math.trunc(prizeNumber).toLocaleString('en-US'),
    dates: cleanDates,
    month: `${dateTokens[0]} ${dateTokens[dateTokens.length - 1]}`,
    size: '4 TEAMS',
    field: teamIds,
    champion: null,
    note: '4 teams registered',
    glyph: NEW_GLYPHS[store.created.length % NEW_GLYPHS.length],
  };
  const matches = [
    { id: maxId + 1, t: code, round: 1, slot: 1, time: 'DAY 1 · 15:00', sides: null },
    { id: maxId + 2, t: code, round: 1, slot: 2, time: 'DAY 1 · 18:00', sides: null },
    { id: maxId + 3, t: code, round: 2, slot: 1, time: 'DAY 2 · 17:00', sides: null },
  ];

  TOURNAMENTS.splice(1, 0, tournament);
  MATCHES.push(...matches);
  store.created.push({ tournament, matches });
  saveStore();
  reconcileElimTournaments();
  return { ok: true, code };
}

export function saveCreator(id, fields) {
  const clean = {
    name: String(fields && fields.name || '').trim(),
    twitch: String(fields && fields.twitch || '').trim(),
    instagram: String(fields && fields.instagram || '').trim(),
    twitter: String(fields && fields.twitter || '').trim(),
    pic: String(fields && fields.pic || '').trim(),
  };
  if (!clean.name) return { ok: false, error: 'name required' };
  if (!clean.twitch && !clean.instagram && !clean.twitter) return { ok: false, error: 'at least one link required' };

  if (id == null) {
    const nextId = CREATORS.length ? Math.max(...CREATORS.map((creator) => creator.id)) + 1 : 1;
    CREATORS.push({ id: nextId, ...clean });
    persistCreators();
    return { ok: true, id: nextId };
  }

  const creatorId = Number(id);
  const creator = CREATORS.find((entry) => entry.id === creatorId);
  if (!creator) return { ok: false, error: 'creator not found' };
  Object.assign(creator, clean);
  persistCreators();
  return { ok: true, id: creatorId };
}

export function assignCreator({ creatorId, code, role, rate }) {
  const cleanCreatorId = Number(creatorId);
  const cleanCode = String(code || '').trim();
  const cleanRole = String(role || '').trim();
  const cleanRate = Number(rate);

  if (!CREATORS.some((creator) => creator.id === cleanCreatorId)) return { ok: false, error: 'creator not found' };
  if (!TOURNAMENTS.some((event) => event.code === cleanCode)) return { ok: false, error: 'event not found' };
  if (!cleanRole) return { ok: false, error: 'role required' };
  if (String(rate).trim() === '' || !Number.isFinite(cleanRate) || cleanRate < 0) return { ok: false, error: 'rate must be nonnegative' };
  if (CREATOR_ASSIGNMENTS.some((assignment) => assignment.creatorId === cleanCreatorId && assignment.code === cleanCode)) {
    return { ok: false, error: 'already assigned to that event' };
  }

  CREATOR_ASSIGNMENTS.push({
    creatorId: cleanCreatorId,
    code: cleanCode,
    role: cleanRole,
    rate: cleanRate,
    status: 'active',
  });
  persistCreators();
  return { ok: true };
}

export function removeAssignment(creatorId, code) {
  const cleanCreatorId = Number(creatorId);
  const cleanCode = String(code || '').trim();
  const index = CREATOR_ASSIGNMENTS.findIndex((assignment) => assignment.creatorId === cleanCreatorId && assignment.code === cleanCode);
  if (index >= 0) {
    CREATOR_ASSIGNMENTS.splice(index, 1);
    persistCreators();
  }
  return { ok: true };
}

function stampNow() {
  const now = new Date();
  return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
}

function playerCheckinEvent(code) {
  const cleanCode = String(code || '').trim();
  const event = TOURNAMENTS.find((t) => t.code === cleanCode);
  if (!event || event.format !== 'elim' || !Array.isArray(event.field)) return { ok: false, error: 'event not found' };
  return { ok: true, code: cleanCode, event };
}

export function playerCheckinsFor(code) {
  return playerCheckins[String(code || '').trim()] || {};
}

export function playerCheckIn(code, pid) {
  const cleanPid = Number(pid);
  const checkedEvent = playerCheckinEvent(code);
  if (!checkedEvent.ok) return checkedEvent;

  const player = PLAYERS[cleanPid];
  if (!player) return { ok: false, error: 'player not found' };
  if (!checkedEvent.event.field.includes(player[1])) return { ok: false, error: 'player not registered' };

  const eventCheckins = playerCheckins[checkedEvent.code] || (playerCheckins[checkedEvent.code] = {});
  if (eventCheckins[String(cleanPid)]) return { ok: false, error: 'already checked in' };

  eventCheckins[String(cleanPid)] = stampNow();
  saveStore();
  return { ok: true };
}

export function undoPlayerCheckIn(code, pid) {
  const cleanCode = String(code || '').trim();
  const cleanPid = String(Number(pid));
  if (playerCheckins[cleanCode] && playerCheckins[cleanCode][cleanPid]) {
    delete playerCheckins[cleanCode][cleanPid];
    saveStore();
  }
  return { ok: true };
}

export function checkInTeam(code, teamId) {
  const cleanTeamId = Number(teamId);
  const checkedEvent = playerCheckinEvent(code);
  if (!checkedEvent.ok) return checkedEvent;
  if (!checkedEvent.event.field.includes(cleanTeamId)) {
    return { ok: false, error: 'team not registered' };
  }

  const eventCheckins = playerCheckins[checkedEvent.code] || (playerCheckins[checkedEvent.code] = {});
  const time = stampNow();
  let stamped = 0;
  rosterOf(cleanTeamId).forEach((player) => {
    const key = String(player.id);
    if (!eventCheckins[key]) {
      eventCheckins[key] = time;
      stamped += 1;
    }
  });

  saveStore();
  return { ok: true, stamped };
}

export function undoTeam(code, teamId) {
  const cleanCode = String(code || '').trim();
  const cleanTeamId = Number(teamId);
  const eventCheckins = playerCheckins[cleanCode];
  if (eventCheckins) {
    rosterOf(cleanTeamId).forEach((player) => {
      delete eventCheckins[String(player.id)];
    });
    saveStore();
  }
  return { ok: true };
}

export function resetDemo() {
  try {
    if (globalThis.localStorage) globalThis.localStorage.removeItem(STORE_KEY);
  } catch {
    // The page reload below resets in-memory state for blocked storage.
  }
  globalThis.location.reload();
}

applyOverrides();

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
