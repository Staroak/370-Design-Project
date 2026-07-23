#    Project Schedule

- Sprint No. Working Period Weight Due Date
- Project Kick-off 6 July 2026 - 17 July 2026 0% 17 July 2026 11:59 pm
- Sprint 1 18 July 2026 - 24 July 2026 20% 24 July 2026 11:59 pm
- Sprint 2 25 July 2026 - 31 July 2026 20% 31 July 2026 11:59 pm
- Sprint 3 1 August 2026 - 7 August 2026 20% 7 August 2026 11:59 pm
- Sprint 4 8 August 2026 - 14 August 2026 20% 14 August 2026 11:59 pm
- Sprint 5 15 August 2026 - 21 August 2026 20% 21 August 2026 11:59 pm

Project:
Creating a database that helps organize creator tournaments for online games and esports. Handles and tracks tournaments, tournament details (time and date), sponsorship contracts, deliverables, finances (revenue/expenses), and prize payouts. 

## Initial Functional requirements list:

# What tourney organizers would want to see:

- Add users to organizations / teams with role
- Create tournaments per organization, with games, dates, formatting, status, prize pool
- Registering players/teams per tourney
- Records and track match scores, results, winners
- Allow multiple organizations to use one shared database while keeping each org's data isolated.
- All of the organizations and teams that are participating
- Track past player performances
- Track content creator links, if displaying sponsor ads, clicks
- Track Prize payouts & payment status
- Organizers can assign staff/casters/mods and record their payments
- Record revenue and expenses per organization and per tourney
- Event organizers have the ability to add different components to the database such as prize pool, participating teams, and revenue/expenses
- Be able to create reports of profit, sponsor fulfillment and outstanding payments
- Track sponsorship contracts
- Track Content deliverables
- Roles: Admin, staff, esports organization, players/teams, audience (security hierarchy, most to least)
- Track payment logs of each staff (crew/casters/mods) member / winning teams

# What the players/team/audience would want to see:

- Audience can also access database to check for information regarding the event
- Players and team stats
- Time and date of games and tournaments
- Which players and teams are participating
- Total prize pool
- Game schedules
- Event times and dates


## Business Requirements:

- Track each player's individual stats and past performance history
- Identify which sponsors are worth renewing for future events.
- Know outstanding payments (for talent/crew/staff and winners)
- Know whether sponsors deliverables were fulfilled
- Know if a tourney was profitable

Note* Data will be generated as realistic mock data. Can scrape liquidpedia and existing TO company data (if they let us)

# Plan for Sprint 0:

- Form group and scope out the idea
- Discuss ideas with group members and create functional requirements list


## Plan for Sprint 1

- Implement the ERD's syntax to create an initial layout of our database and to explain how the different components relate - will satisfy Basic conceptual desgin
- Implement the usage of multiplicity to organize and direct relations
- Split information into different attributes, entity sets, relationships, identifiers, etc.
- Be able to identify different functional dependencies, and anomalies
- Identify and develop contraints


# Status Report for Sprint 1

## Conceptual Design

### Entities

**Organization**
- Attributes: org_id(PK), org_name, contact_email, created_date, region
- FDs:
  - org_id -> org_name, contact_email, created_date, region
- Constraints:
  - org_id unique and not null
  - created_date <= current date


**Users**
- Attributes: user_id(PK), full_name, email, password, phone
- FDs:
  - user_id -> full_name, email, password, phone
  - email -> user_id, full_name, password, phone (email is a second candidate key)
- Constraints:
  - user_id and email unique and not null

**Game**
- Attributes: game_id(PK), title, genre, publisher
- FDs:
  - game_id -> title, genre, publisher
- Constraints:
  - game_id and title unique (publisher is not unique - one publisher makes many games)

**Tournament**
- Attributes: tournament_id(PK), org_id(FK), game_id(FK), name, start_date, end_date, format, status, prize_pool
- FDs:
  - tournament_id -> org_id, game_id, name, start_date, end_date, format, status, prize_pool
- Constraints:
  - org_id references an existing Organization
  - game_id references an existing Game
  - start_date <= end_date
  - prize_pool >= 0

**Teams**
- Attributes: team_id(PK), team_name, region, founded_date, game_id(FK), linked_org
- FDs:
  - team_id -> team_name, region, founded_date, game_id, linked_org
- Constraints:
  - team_name must be unique
  - founded_date < current date
  - linked_org references an existing Organization, or is null

**Players**
- Attributes: player_id(PK), ign, real_name, country, birth_date
- FDs:
  - player_id -> ign, real_name, country, birth_date
- Constraints:
  - ign must be unique
  - birth_date < current date

**Match**
- Attributes: match_id(PK), tournament_id(FK), scheduled_time, team1_id(FK), team2_id(FK), winner_team_id(FK), final_score
- FDs:
  - match_id -> tournament_id, scheduled_time, team1_id, team2_id, winner_team_id, final_score
- Constraints:
  - team1_id != team2_id (a team can't play itself)
  - winner_team_id must equal team1_id or team2_id (exactly one)
  - scheduled_time must fall within the tournament's date range
  - final_score > 0

**Sponsors**
- Attributes: sponsor_id(PK), company_name, contact_name, contact_email
- FDs:
  - sponsor_id -> company_name, contact_name, contact_email
- Constraints:
  - company_name must be unique

**Contracts**
- Attributes: contract_id(PK), org_id(FK), tournament_id(FK), party_type(sponsor/creator), sponsor_id(FK), creator_id(FK), start_date, end_date, total_value
- FDs:
  - contract_id -> org_id, tournament_id, party_type, sponsor_id, creator_id, start_date, end_date, total_value
- Constraints:
  - start_date < end_date
  - total_value > 0
  - party_type = sponsor -> sponsor_id filled, creator_id null
  - party_type = creator -> creator_id filled, sponsor_id null

**Creators**
- Attributes: creator_id(PK), twitchlink, instagram, twitter, profile_pic
- FDs:
  - creator_id -> twitchlink, instagram, twitter, profile_pic
- Constraints:
  - at least one social media link must be filled
  - creator_id unique

**Deliverables**
- Attributes: deliverable_id(PK), contract_id(FK), description, type, due_date, status, click_count
- FDs:
  - deliverable_id -> contract_id, description, type, due_date, status, click_count
- Constraints:
  - click_count >= 0
  - description must be filled

**Transactions**
- Attributes: transaction_id(PK), org_id(FK), tournament_id(FK), type(revenue/expense), category, amount, date
- FDs:
  - transaction_id -> org_id, tournament_id, type, category, amount, date
- Constraints:
  - type is either revenue or expense
  - amount >= 0
  - tournament_id may be null (org-level transactions)

**Payments**
- Attributes: payment_id(PK), payee_type(staff/team), staff_user_id(FK), team_id(FK), tournament_id(FK), amount, status, payment_date
- FDs:
  - payment_id -> payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date
- Constraints:
  - payee_type is either staff or team
  - amount > 0
  - exactly one of staff_user_id / team_id is filled:
    - payee_type = staff -> staff_user_id filled, team_id null
    - payee_type = team -> team_id filled, staff_user_id null

### Relationships (junction tables: multiplicity)

**Membership** - Users <-> Organization (M:N)
- Attributes: user_id(FK), org_id(FK), role, joined_date, left_date; PK {user_id, org_id}
- Constraints:
  - joined_date not null
  - left_date null or >= joined_date (null = active member)

**Registration** - Team <-> Tournament (M:N)
- Attributes: team_id(FK), tournament_id(FK), registration_date, seed; PK {team_id, tournament_id}
- Constraints:
  - team and tournament must be for the same game

**Roster** - Player <-> Team (M:N)
- Attributes: roster_id(PK), player_id(FK), team_id(FK), join_date, leave_date, salary, jersey_number
- Constraints:
  - no player on two active teams
  - join_date <= leave_date
  - salary >= 0
  - jersey_number unique within the team

**StaffAssignments** - Users <-> Tournament (M:N)
- Attributes: user_id(FK), tournament_id(FK), staff_role, pay_amount; PK {user_id, tournament_id}
- Constraints:
  - pay_amount >= 0
  - user can't be assigned to overlapping tournaments
  - user can only have one assignment per tournament and role
  - user must belong to the organization running the tournament

**PlayerMatchStats** - Player <-> Match (M:N)
- Attributes: player_id(FK), match_id(FK), kills, deaths, assists, score; PK {player_id, match_id}
- Constraints:
  - no player in two matches at once
  - kills, deaths, assists, score >= 0

**CreatorAssignment** - Creator <-> Tournament (M:N)
- Attributes: creator_id(FK), tournament_id(FK), role, rate, status; PK {creator_id, tournament_id}
- Constraints:
  - creator must have an active role

**StaffMatches** - Users <-> Match (M:N)
- Attributes: user_id(FK), match_id(FK), role
- Constraints:
  - user cannot be assigned to matches with overlapping times

**CreatorMatches** - Creator <-> Match (M:N)
- Attributes: creator_id(FK), match_id(FK)
- Constraints:
  - no overlapping match times
  - at least 1 creator per match

## Plan for Sprint 2
- Identify BCNF Decomposition
- Write out some of the basic tables and populate with some mock data. 
- Implement schemas in SQL
- Create scenarios on the usability of our db and write lines of SQL to test how we can pull information
- Briefly review sprint 1 and attempt to identify any components or important details we have missed
