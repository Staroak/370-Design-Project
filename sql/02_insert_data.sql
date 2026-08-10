USE design_project_370;


-- ============================ REAL DATA ==============================

-- Game (real)
INSERT INTO Game (title, genre, publisher) VALUES
    ('Valorant', 'Tactical Shooter', 'Riot Games');

-- EsportsOrg (parent orgs, derived from real MTB/QOR player tags)
INSERT INTO EsportsOrg (name, region, founded_date) VALUES
    ('MTB', 'NA', '2022-01-01')
  , ('QOR', 'NA', '2021-06-01');

-- Teams (real, APPROVED Creator Cup teams)
INSERT INTO Teams (team_name, region, founded_date, game_id, esports_org_id) VALUES
    ('Triple T''s Sahurs', NULL, NULL, 1, 1)
  , ('The Almond Joys', NULL, NULL, 1, NULL)
  , ('Monkey Lovers', NULL, NULL, 1, NULL)
  , ('Elements of Harmony', NULL, NULL, 1, 2)
  , ('MENAces', NULL, NULL, 1, 2)
  , ('valorant enjoyers', NULL, NULL, 1, NULL)
  , ('AURAA Farmers', NULL, NULL, 1, NULL)
  , ('Roku Nana', NULL, NULL, 1, NULL);

-- Competitor (each of the 8 real teams enters as a 'team' competitor).
-- IDs are explicit here because the rest of the file depends on the
-- competitor_id -> team_id / player_id mapping being readable.
INSERT INTO Competitor (competitor_id, competitor_type, team_id, player_id) VALUES
    (1, 'team', 1, NULL)               -- Triple T's Sahurs
  , (2, 'team', 2, NULL)               -- The Almond Joys
  , (3, 'team', 3, NULL)               -- Monkey Lovers
  , (4, 'team', 4, NULL)               -- Elements of Harmony
  , (5, 'team', 5, NULL)               -- MENAces
  , (6, 'team', 6, NULL)               -- valorant enjoyers
  , (7, 'team', 7, NULL)               -- AURAA Farmers
  , (8, 'team', 8, NULL);              -- Roku Nana

-- Players (real IGNs; real_name/country/birth_date unknown -> NULL)
INSERT INTO Players (ign, real_name, country, birth_date) VALUES
    ('aus#MTB', NULL, NULL, NULL)
  , ('xixi#0830', NULL, NULL, NULL)
  , ('carp#444', NULL, NULL, NULL)
  , ('Sleepy Femboy#rawr', NULL, NULL, NULL)
  , ('madge#koow', NULL, NULL, NULL)
  , ('im still shining#almor', NULL, NULL, NULL)
  , ('Coach Lobster#Coach', NULL, NULL, NULL)
  , ('playn with toes#toes', NULL, NULL, NULL)
  , ('Sa1ty#123', NULL, NULL, NULL)
  , ('skytookie#sub', NULL, NULL, NULL)
  , ('kaleiydo#scope', NULL, NULL, NULL)
  , ('SeijinTea#TTV', NULL, NULL, NULL)
  , ('sandtose#9610', NULL, NULL, NULL)
  , ('ML revrzd#gato', NULL, NULL, NULL)
  , ('josepi#jac', NULL, NULL, NULL)
  , ('vicesippy#BIGT', NULL, NULL, NULL)
  , ('Tekkni#Shoot', NULL, NULL, NULL)
  , ('Zalphine#Snort', NULL, NULL, NULL)
  , ('BangBang#Panda', NULL, NULL, NULL)
  , ('thecanadiancooki#SKZ', NULL, NULL, NULL)
  , ('QOR ttinybones#AAAAA', NULL, NULL, NULL)
  , ('Jane Doe#ChitZ', NULL, NULL, NULL)
  , ('QOR hamouduh#Syria', NULL, NULL, NULL)
  , ('singularity#kiwi', NULL, NULL, NULL)
  , ('olivegrovepapi#ttv', NULL, NULL, NULL)
  , ('DoctorMoesy#TTV', NULL, NULL, NULL)
  , ('m0ld#dems', NULL, NULL, NULL)
  , ('navi#look', NULL, NULL, NULL)
  , ('shawarma#xtoum', NULL, NULL, NULL)
  , ('ekittenuwuboy67#lumei', NULL, NULL, NULL)
  , ('happycamper#1018', NULL, NULL, NULL)
  , ('laki#plays', NULL, NULL, NULL)
  , ('juicebox#kitty', NULL, NULL, NULL)
  , ('silly penguin13#dae', NULL, NULL, NULL)
  , ('oni#AURAA', NULL, NULL, NULL)
  , ('Colt#GGTTV', NULL, NULL, NULL)
  , ('Rocke#813', NULL, NULL, NULL)
  , ('Kairu#1473', NULL, NULL, NULL)
  , ('icarus 407#VGS47', NULL, NULL, NULL)
  , ('sig too clean#ttv', NULL, NULL, NULL)
  , ('chuwy#kiki', NULL, NULL, NULL)
  , ('JareBear#TTV', NULL, NULL, NULL)
  , ('dberg#omen', NULL, NULL, NULL)
  , ('versi#nat', NULL, NULL, NULL)
  , ('lil chicken wrap#ranch', NULL, NULL, NULL)
  , ('BIG PT#OTOWN', NULL, NULL, NULL);

-- Roster (real: main players jerseys 1-5, subs 6+; salary mocked as NULL)
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number) VALUES
    (1, 1, NULL, NULL, NULL, 1)
  , (2, 1, NULL, NULL, NULL, 2)
  , (3, 1, NULL, NULL, NULL, 3)
  , (4, 1, NULL, NULL, NULL, 4)
  , (5, 1, NULL, NULL, NULL, 5)
  , (6, 2, NULL, NULL, NULL, 1)
  , (7, 2, NULL, NULL, NULL, 2)
  , (8, 2, NULL, NULL, NULL, 3)
  , (9, 2, NULL, NULL, NULL, 4)
  , (10, 2, NULL, NULL, NULL, 5)
  , (11, 3, NULL, NULL, NULL, 1)
  , (12, 3, NULL, NULL, NULL, 2)
  , (13, 3, NULL, NULL, NULL, 3)
  , (14, 3, NULL, NULL, NULL, 4)
  , (15, 3, NULL, NULL, NULL, 5)
  , (16, 3, NULL, NULL, NULL, 6)
  , (17, 4, NULL, NULL, NULL, 1)
  , (18, 4, NULL, NULL, NULL, 2)
  , (19, 4, NULL, NULL, NULL, 3)
  , (20, 4, NULL, NULL, NULL, 4)
  , (21, 4, NULL, NULL, NULL, 5)
  , (22, 4, NULL, NULL, NULL, 6)
  , (23, 5, NULL, NULL, NULL, 1)
  , (24, 5, NULL, NULL, NULL, 2)
  , (25, 5, NULL, NULL, NULL, 3)
  , (26, 5, NULL, NULL, NULL, 4)
  , (27, 5, NULL, NULL, NULL, 5)
  , (28, 5, NULL, NULL, NULL, 6)
  , (29, 5, NULL, NULL, NULL, 7)
  , (30, 6, NULL, NULL, NULL, 1)
  , (31, 6, NULL, NULL, NULL, 2)
  , (32, 6, NULL, NULL, NULL, 3)
  , (33, 6, NULL, NULL, NULL, 4)
  , (34, 6, NULL, NULL, NULL, 5)
  , (35, 7, NULL, NULL, NULL, 1)
  , (36, 7, NULL, NULL, NULL, 2)
  , (37, 7, NULL, NULL, NULL, 3)
  , (38, 7, NULL, NULL, NULL, 4)
  , (39, 7, NULL, NULL, NULL, 5)
  , (40, 7, NULL, NULL, NULL, 6)
  , (41, 7, NULL, NULL, NULL, 7)
  , (42, 8, NULL, NULL, NULL, 1)
  , (43, 8, NULL, NULL, NULL, 2)
  , (44, 8, NULL, NULL, NULL, 3)
  , (45, 8, NULL, NULL, NULL, 4)
  , (46, 8, NULL, NULL, NULL, 5);


-- ============================ MOCK DATA ==============================

-- Organization (tournament organizer)
INSERT INTO Organization (org_name, contact_email, created_date, region) VALUES
    ('MTB Events', 'staff@mtbevents.gg', '2024-01-01', 'NA');

-- Tournament 1 = the real Creator Cup; Tournament 2 = mock follow-up event
INSERT INTO Tournament (org_id, game_id, name, start_date, end_date, format, status, prize_pool) VALUES
    (1, 1, 'Creator Cup',       '2026-03-14', '2026-03-16', 'Single Elimination', 'completed', 5000.00)
  , (1, 1, 'MTB Winter Clash',  '2026-04-11', '2026-04-12', 'Single Elimination', 'completed', 3000.00);

-- Registration (real: all 8 teams -> Creator Cup; top 4 -> Winter Clash).
-- competitor_id 1-8 are the 'team' competitors for teams 1-8.
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed) VALUES
    (1, 1, '2026-03-01', 1)
  , (2, 1, '2026-03-01', 2)
  , (3, 1, '2026-03-01', 3)
  , (4, 1, '2026-03-01', 4)
  , (5, 1, '2026-03-01', 5)
  , (6, 1, '2026-03-01', 6)
  , (7, 1, '2026-03-01', 7)
  , (8, 1, '2026-03-01', 8)
  , (1, 2, '2026-04-01', 1)
  , (2, 2, '2026-04-01', 2)
  , (3, 2, '2026-04-01', 3)
  , (4, 2, '2026-04-01', 4);

-- Users (captains from the real data + tournament staff)
INSERT INTO Users (full_name, email, password, phone) VALUES
    ('milkteaboards', 'milkteaboards@players.gg', 'hash', NULL)
  , ('almondfps', 'almondfps@players.gg', 'hash', NULL)
  , ('kaleiydo', 'kaleiydo@players.gg', 'hash', NULL)
  , ('ttinybones', 'ttinybones@players.gg', 'hash', NULL)
  , ('hamouduh', 'hamouduh@players.gg', 'hash', NULL)
  , ('daeunnie', 'daeunnie@players.gg', 'hash', NULL)
  , ('oniaura', 'oniaura@players.gg', 'hash', NULL)
  , ('jarebeartv', 'jarebeartv@players.gg', 'hash', NULL)
  , ('Tournament Admin', 'admin@mtbevents.gg', 'hash', NULL)
  , ('Head Caster', 'caster@mtbevents.gg', 'hash', NULL)
  , ('Lead Moderator', 'mod@mtbevents.gg', 'hash', NULL)
  , ('Broadcast Producer', 'producer@mtbevents.gg', 'hash', NULL);

-- Membership (staff users belong to the organizer; admin role for Q10)
INSERT INTO Membership (user_id, org_id, role, joined_date, left_date) VALUES
    (9, 1, 'admin',     '2024-01-01', NULL)
  , (10, 1, 'caster',    '2024-02-01', NULL)
  , (11, 1, 'moderator', '2024-02-01', NULL)
  , (12, 1, 'producer',  '2024-03-01', NULL);

-- StaffAssignments (staff -> tournaments)
INSERT INTO StaffAssignments (user_id, tournament_id, staff_role, pay_amount) VALUES
    (9, 1, 'admin',     0.00)
  , (10, 1, 'caster',    500.00)
  , (11, 1, 'moderator', 300.00)
  , (12, 2, 'producer',  400.00);

-- Match (mock bracket over the real teams). Who played and who won now lives
-- in MatchParticipant, not in team1_id/team2_id/winner_team_id.
INSERT INTO `Match` (tournament_id, scheduled_time, final_score) VALUES
    (1, '2026-03-14 12:00:00', '13-7')      -- match 1  QF
  , (1, '2026-03-14 13:30:00', '13-10')     -- match 2  QF
  , (1, '2026-03-14 15:00:00', '13-4')      -- match 3  QF
  , (1, '2026-03-14 16:30:00', '13-9')      -- match 4  QF
  , (1, '2026-03-15 12:00:00', '13-11')     -- match 5  SF
  , (1, '2026-03-15 14:00:00', '11-13')     -- match 6  SF
  , (1, '2026-03-16 15:00:00', '13-8')      -- match 7  final
  , (2, '2026-04-11 13:00:00', '13-6')      -- match 8  SF
  , (2, '2026-04-11 15:00:00', '13-9')      -- match 9  SF
  , (2, '2026-04-12 15:00:00', '9-13');     -- match 10 final

-- MatchParticipant for the Valorant bracket: 2 competitors per match,
-- placement 1 = winner / 2 = loser, 1 point for a win in an elimination format.
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points) VALUES
    (1,  1, 1, 1), (1,  8, 2, 0)
  , (2,  4, 1, 1), (2,  5, 2, 0)
  , (3,  3, 1, 1), (3,  6, 2, 0)
  , (4,  2, 1, 1), (4,  7, 2, 0)
  , (5,  1, 1, 1), (5,  4, 2, 0)
  , (6,  2, 1, 1), (6,  3, 2, 0)
  , (7,  1, 1, 1), (7,  2, 2, 0)
  , (8,  1, 1, 1), (8,  4, 2, 0)
  , (9,  2, 1, 1), (9,  3, 2, 0)
  , (10, 2, 1, 1), (10, 1, 2, 0);

-- PlayerMatchStats (mock stats for the real players in each match)
INSERT INTO PlayerMatchStats (player_id, match_id, kills, deaths, assists, score) VALUES
    (1, 1, 12, 8, 11, 178)
  , (2, 1, 25, 15, 6, 195)
  , (3, 1, 20, 10, 11, 212)
  , (4, 1, 15, 17, 6, 229)
  , (5, 1, 10, 12, 11, 246)
  , (42, 1, 23, 19, 6, 275)
  , (43, 1, 18, 14, 11, 292)
  , (44, 1, 13, 9, 6, 309)
  , (45, 1, 26, 16, 11, 326)
  , (46, 1, 21, 11, 6, 343)
  , (17, 2, 11, 17, 4, 261)
  , (18, 2, 24, 12, 9, 278)
  , (19, 2, 19, 19, 4, 295)
  , (20, 2, 14, 14, 9, 312)
  , (21, 2, 27, 9, 4, 329)
  , (23, 2, 17, 11, 4, 163)
  , (24, 2, 12, 18, 9, 180)
  , (25, 2, 25, 13, 4, 197)
  , (26, 2, 20, 8, 9, 214)
  , (27, 2, 15, 15, 4, 231)
  , (11, 3, 12, 16, 7, 170)
  , (12, 3, 25, 11, 12, 187)
  , (13, 3, 20, 18, 7, 204)
  , (14, 3, 15, 13, 12, 221)
  , (15, 3, 10, 8, 7, 238)
  , (30, 3, 25, 17, 12, 293)
  , (31, 3, 20, 12, 7, 310)
  , (32, 3, 15, 19, 12, 327)
  , (33, 3, 10, 14, 7, 344)
  , (34, 3, 23, 9, 12, 161)
  , (6, 4, 26, 10, 5, 296)
  , (7, 4, 21, 17, 10, 313)
  , (8, 4, 16, 12, 5, 330)
  , (9, 4, 11, 19, 10, 347)
  , (10, 4, 24, 14, 5, 164)
  , (35, 4, 25, 9, 10, 189)
  , (36, 4, 20, 16, 5, 206)
  , (37, 4, 15, 11, 10, 223)
  , (38, 4, 10, 18, 5, 240)
  , (39, 4, 23, 13, 10, 257)
  , (1, 5, 22, 16, 3, 222)
  , (2, 5, 17, 11, 8, 239)
  , (3, 5, 12, 18, 3, 256)
  , (4, 5, 25, 13, 8, 273)
  , (5, 5, 20, 8, 3, 290)
  , (17, 5, 14, 8, 3, 294)
  , (18, 5, 27, 15, 8, 311)
  , (19, 5, 22, 10, 3, 328)
  , (20, 5, 17, 17, 8, 345)
  , (21, 5, 12, 12, 3, 162)
  , (11, 6, 15, 19, 6, 203)
  , (12, 6, 10, 14, 11, 220)
  , (13, 6, 23, 9, 6, 237)
  , (14, 6, 18, 16, 11, 254)
  , (15, 6, 13, 11, 6, 271)
  , (6, 6, 22, 8, 11, 318)
  , (7, 6, 17, 15, 6, 335)
  , (8, 6, 12, 10, 11, 152)
  , (9, 6, 25, 17, 6, 169)
  , (10, 6, 20, 12, 11, 186)
  , (1, 7, 18, 14, 9, 244)
  , (2, 7, 13, 9, 4, 261)
  , (3, 7, 26, 16, 9, 278)
  , (4, 7, 21, 11, 4, 295)
  , (5, 7, 16, 18, 9, 312)
  , (6, 7, 11, 13, 4, 329)
  , (7, 7, 24, 8, 9, 346)
  , (8, 7, 19, 15, 4, 163)
  , (9, 7, 14, 10, 9, 180)
  , (10, 7, 27, 17, 4, 197)
  , (1, 8, 25, 19, 12, 255)
  , (2, 8, 20, 14, 7, 272)
  , (3, 8, 15, 9, 12, 289)
  , (4, 8, 10, 16, 7, 306)
  , (5, 8, 23, 11, 12, 323)
  , (17, 8, 17, 11, 12, 327)
  , (18, 8, 12, 18, 7, 344)
  , (19, 8, 25, 13, 12, 161)
  , (20, 8, 20, 8, 7, 178)
  , (21, 8, 15, 15, 12, 195)
  , (6, 9, 25, 11, 10, 151)
  , (7, 9, 20, 18, 5, 168)
  , (8, 9, 15, 13, 10, 185)
  , (9, 9, 10, 8, 5, 202)
  , (10, 9, 23, 15, 10, 219)
  , (11, 9, 18, 10, 5, 236)
  , (12, 9, 13, 17, 10, 253)
  , (13, 9, 26, 12, 5, 270)
  , (14, 9, 21, 19, 10, 287)
  , (15, 9, 16, 14, 5, 304)
  , (1, 10, 21, 17, 8, 277)
  , (2, 10, 16, 12, 3, 294)
  , (3, 10, 11, 19, 8, 311)
  , (4, 10, 24, 14, 3, 328)
  , (5, 10, 19, 9, 8, 345)
  , (6, 10, 14, 16, 3, 162)
  , (7, 10, 27, 11, 8, 179)
  , (8, 10, 22, 18, 3, 196)
  , (9, 10, 17, 13, 8, 213)
  , (10, 10, 12, 8, 3, 230);

-- StaffMatches (caster + moderator work select matches)
INSERT INTO StaffMatches (user_id, match_id, role) VALUES
    (10, 7, 'caster')
  , (10, 10, 'caster')
  , (11, 7, 'moderator');

-- Creators (some captains streamed; at least one social link each)
INSERT INTO Creators (twitchlink, instagram, twitter, profile_pic) VALUES
    ('twitch.tv/revrzd', NULL, NULL, NULL)
  , (NULL, 'instagram.com/almondfps', NULL, NULL)
  , (NULL, NULL, 'twitter.com/jarebeartv', NULL);

-- CreatorAssignment (creators cover the tournaments)
INSERT INTO CreatorAssignment (creator_id, tournament_id, role, rate, status) VALUES
    (1, 1, 'streamer', 500.00, 'active')
  , (2, 1, 'host',     400.00, 'active')
  , (3, 2, 'streamer', 350.00, 'active');

-- CreatorMatches (creators stream select matches)
INSERT INTO CreatorMatches (creator_id, match_id) VALUES
    (1, 7)
  , (1, 5)
  , (2, 7);

-- Sponsors
INSERT INTO Sponsors (company_name, contact_name, contact_email) VALUES
    ('Red Bull', 'Maria Lopez', 'esports@redbull.com')
  , ('Logitech', 'Jane Doe',    'partners@logitech.com')
  , ('Discord',  'Sam Chen',    'brand@discord.com');

-- Contracts (sponsor + creator; party_type XOR enforced by schema)
INSERT INTO Contracts (org_id, tournament_id, party_type, sponsor_id, creator_id, start_date, end_date, total_value) VALUES
    (1, 1, 'sponsor', 1,    NULL, '2026-01-01', '2026-03-16', 5000.00)
  , (1, 1, 'sponsor', 2,    NULL, '2026-01-15', '2026-03-16', 3000.00)
  , (1, 1, 'creator', NULL, 1,    '2026-02-01', '2026-03-16', 800.00)
  , (1, 2, 'sponsor', 3,    NULL, '2026-03-20', '2026-04-12', 2500.00);

-- Deliverables
INSERT INTO Deliverables (contract_id, description, type, due_date, status, click_count) VALUES
    (1, 'Logo on stream overlay',      'branding',   '2026-03-16', 'fulfilled', 0)
  , (1, 'Mid-event sponsor segment',   'activation', '2026-03-15', 'fulfilled', 0)
  , (2, 'Product giveaway',            'activation', '2026-03-16', 'fulfilled', 0)
  , (2, 'Banner ad on broadcast',      'branding',   '2026-03-16', 'pending',   0)
  , (3, '2 promotional videos',        'content',    '2026-03-10', 'pending',   3200)
  , (4, 'Discord server integration',  'activation', '2026-04-12', 'fulfilled', 0);

-- Transactions (drives the profitability query)
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date) VALUES
    (1, 1, 'revenue', 'sponsorship',  8000.00, '2026-03-01')
  , (1, 1, 'revenue', 'ticket sales', 1500.00, '2026-03-16')
  , (1, 1, 'expense', 'prize payout', 5000.00, '2026-03-17')
  , (1, 1, 'expense', 'production',   2000.00, '2026-03-16')
  , (1, 1, 'expense', 'staff',        1200.00, '2026-03-17')
  , (1, 2, 'revenue', 'sponsorship',  2500.00, '2026-04-01')
  , (1, 2, 'expense', 'prize payout', 3000.00, '2026-04-13');

-- Payments (prize payouts + staff; some pending for the outstanding query)
INSERT INTO Payments (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date) VALUES
    ('team',  NULL, 1, 1, 3000.00, 'paid',    '2026-03-18')
  , ('team',  NULL, 2, 1, 1500.00, 'paid',    '2026-03-18')
  , ('team',  NULL, 2, 2, 2000.00, 'pending', NULL)
  , ('staff', 10,   NULL, 1, 500.00, 'paid',    '2026-03-18')
  , ('staff', 11,   NULL, 1, 300.00, 'pending', NULL);


-- ================= SOLO / POINTS-BY-PLACEMENT EVENTS =================
-- Sprint 3 goal: prove the results model is not limited to 2-team matches.
-- Two cases are seeded below:
--   Tournament 3 = an 8-player Teamfight Tactics lobby series (points by placement)
--   Tournament 4 = a Rocket League 1v1 best-of-3 (one player per side)

-- Games 2 and 3
INSERT INTO Game (title, genre, publisher) VALUES
    ('Teamfight Tactics', 'Auto Battler', 'Riot Games')      -- game_id 2
  , ('Rocket League',     'Sports',       'Psyonix');        -- game_id 3

-- Solo players: 8 TFT entrants (player_id 47-54) + 2 duellists (55-56)
INSERT INTO Players (ign, real_name, country, birth_date) VALUES
    ('Setsuko#TFT', NULL, NULL, NULL)          -- 47
  , ('kiyoomi#EUW', NULL, NULL, NULL)          -- 48
  , ('Rerolla#NA1', NULL, NULL, NULL)          -- 49
  , ('Augment#0001', NULL, NULL, NULL)         -- 50
  , ('TinyLegend#tft', NULL, NULL, NULL)       -- 51
  , ('Carousel#spin', NULL, NULL, NULL)        -- 52
  , ('Fortune#4win', NULL, NULL, NULL)         -- 53
  , ('HyperRoll#top4', NULL, NULL, NULL)       -- 54
  , ('Jstn1v1#RL', NULL, NULL, NULL)           -- 55
  , ('Firstkiller#duel', NULL, NULL, NULL);    -- 56

-- The same 10 players enter as 'player' competitors. No Teams row is needed:
-- this is the case the old team1_id/team2_id schema could not represent.
INSERT INTO Competitor (competitor_id, competitor_type, team_id, player_id) VALUES
    (9,  'player', NULL, 47)
  , (10, 'player', NULL, 48)
  , (11, 'player', NULL, 49)
  , (12, 'player', NULL, 50)
  , (13, 'player', NULL, 51)
  , (14, 'player', NULL, 52)
  , (15, 'player', NULL, 53)
  , (16, 'player', NULL, 54)
  , (17, 'player', NULL, 55)
  , (18, 'player', NULL, 56);

INSERT INTO Tournament (org_id, game_id, name, start_date, end_date, format, status, prize_pool) VALUES
    (1, 2, 'MTB TFT Open',              '2026-05-02', '2026-05-03', 'Points by Placement', 'completed', 2000.00)
  , (1, 3, 'Rocket League 1v1 Showdown', '2026-05-09', '2026-05-09', 'Single Elimination',  'completed', 1000.00);

-- Registration: 8 solo competitors -> TFT (tournament 3), 2 -> 1v1 (tournament 4)
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed) VALUES
    (9,  3, '2026-04-20', 1)
  , (10, 3, '2026-04-20', 2)
  , (11, 3, '2026-04-20', 3)
  , (12, 3, '2026-04-20', 4)
  , (13, 3, '2026-04-20', 5)
  , (14, 3, '2026-04-20', 6)
  , (15, 3, '2026-04-20', 7)
  , (16, 3, '2026-04-20', 8)
  , (17, 4, '2026-05-01', 1)
  , (18, 4, '2026-05-01', 2);

-- Matches 11-12 = the two TFT lobbies; 13-15 = the 1v1 best-of-3.
-- final_score is NULL for TFT: a lobby has no single head-to-head scoreline,
-- the result is the placement of all 8 competitors.
INSERT INTO `Match` (tournament_id, scheduled_time, final_score) VALUES
    (3, '2026-05-02 18:00:00', NULL)      -- match 11  TFT lobby 1
  , (3, '2026-05-03 18:00:00', NULL)      -- match 12  TFT lobby 2
  , (4, '2026-05-09 12:00:00', '4-2')     -- match 13  1v1 game 1
  , (4, '2026-05-09 12:30:00', '2-5')     -- match 14  1v1 game 2
  , (4, '2026-05-09 13:00:00', '3-1');    -- match 15  1v1 game 3 (decider)

-- 8 rows per TFT lobby: placement 1-8, TFT points = 9 - placement.
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points) VALUES
    (11,  9, 1, 8), (11, 10, 2, 7), (11, 11, 3, 6), (11, 12, 4, 5)
  , (11, 13, 5, 4), (11, 14, 6, 3), (11, 15, 7, 2), (11, 16, 8, 1)
  , (12, 11, 1, 8), (12,  9, 2, 7), (12, 13, 3, 6), (12, 10, 4, 5)
  , (12, 16, 5, 4), (12, 12, 6, 3), (12, 14, 7, 2), (12, 15, 8, 1);

-- 2 rows per 1v1 game: exactly one player on each side, no team involved.
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points) VALUES
    (13, 17, 1, 1), (13, 18, 2, 0)
  , (14, 18, 1, 1), (14, 17, 2, 0)
  , (15, 17, 1, 1), (15, 18, 2, 0);

-- Finances for the two new events so the profitability query still covers every tournament
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date) VALUES
    (1, 3, 'revenue', 'sponsorship',  3500.00, '2026-05-01')
  , (1, 3, 'expense', 'prize payout', 2000.00, '2026-05-04')
  , (1, 4, 'revenue', 'ticket sales',  900.00, '2026-05-09')
  , (1, 4, 'expense', 'prize payout', 1000.00, '2026-05-10');
