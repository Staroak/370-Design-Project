USE design_project_370;

-- Drop table so we can re run the file to rebuild the tables.

DROP TABLE IF EXISTS CreatorMatches;
DROP TABLE IF EXISTS StaffMatches;
DROP TABLE IF EXISTS CreatorAssignment;
DROP TABLE IF EXISTS PlayerMatchStats;
DROP TABLE IF EXISTS MatchParticipant;
DROP TABLE IF EXISTS StaffAssignments;
DROP TABLE IF EXISTS Roster;
DROP TABLE IF EXISTS Registration;
DROP TABLE IF EXISTS Membership;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS Deliverables;
DROP TABLE IF EXISTS Contracts;
DROP TABLE IF EXISTS `Match`;
DROP TABLE IF EXISTS Competitor;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS Tournament;
DROP TABLE IF EXISTS Creators;
DROP TABLE IF EXISTS Sponsors;
DROP TABLE IF EXISTS Players;
DROP TABLE IF EXISTS Game;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS EsportsOrg;
DROP TABLE IF EXISTS Organization;



-- GROUP 1 INDEPENDENT ENTITIES (no outgoing foreign keys)


CREATE TABLE Organization (            -- tournament organizer (uses the service)
    org_id         INT           NOT NULL AUTO_INCREMENT
  , org_name       VARCHAR(255)  NOT NULL
  , contact_email  VARCHAR(255)
  , created_date   DATE
  , region         VARCHAR(100)
  , PRIMARY KEY (org_id)
);

CREATE TABLE EsportsOrg (              -- a team's parent org, e.g. TSM, Cloud9
    esports_org_id  INT           NOT NULL AUTO_INCREMENT
  , name            VARCHAR(255)  NOT NULL
  , region          VARCHAR(100)
  , founded_date    DATE
  , PRIMARY KEY (esports_org_id)
  , UNIQUE (name)
);

CREATE TABLE Users (
    user_id    INT           NOT NULL AUTO_INCREMENT
  , full_name  VARCHAR(255)  NOT NULL
  , email      VARCHAR(255)  NOT NULL
  , password   VARCHAR(255)  NOT NULL
  , phone      VARCHAR(30)
  , PRIMARY KEY (user_id)
  , UNIQUE (email)
);

CREATE TABLE Game (
    game_id    INT           NOT NULL AUTO_INCREMENT
  , title      VARCHAR(255)  NOT NULL
  , genre      VARCHAR(100)
  , publisher  VARCHAR(255)
  , PRIMARY KEY (game_id)
  , UNIQUE (title)
);

CREATE TABLE Players (
    player_id   INT           NOT NULL AUTO_INCREMENT
  , ign         VARCHAR(100)  NOT NULL
  , real_name   VARCHAR(255)
  , country     VARCHAR(100)
  , birth_date  DATE
  , PRIMARY KEY (player_id)
  , UNIQUE (ign)
);

CREATE TABLE Sponsors (
    sponsor_id     INT           NOT NULL AUTO_INCREMENT
  , company_name   VARCHAR(255)  NOT NULL
  , contact_name   VARCHAR(255)
  , contact_email  VARCHAR(255)
  , PRIMARY KEY (sponsor_id)
  , UNIQUE (company_name)
);

CREATE TABLE Creators (
    creator_id   INT           NOT NULL AUTO_INCREMENT
  , twitchlink   VARCHAR(255)
  , instagram    VARCHAR(255)
  , twitter      VARCHAR(255)
  , profile_pic  VARCHAR(255)
  , PRIMARY KEY (creator_id)
  , CHECK (twitchlink IS NOT NULL
        OR instagram  IS NOT NULL
        OR twitter    IS NOT NULL)
);


-- GROUP 2 ENTITIES WITH FOREIGN KEYS

CREATE TABLE Tournament (
    tournament_id  INT            NOT NULL AUTO_INCREMENT
  , org_id         INT            NOT NULL
  , game_id        INT            NOT NULL
  , name           VARCHAR(255)   NOT NULL
  , start_date     DATE
  , end_date       DATE
  , format         VARCHAR(100)
  , status         VARCHAR(50)
  , prize_pool     DECIMAL(12,2)
  , PRIMARY KEY (tournament_id)
  , FOREIGN KEY (org_id)  REFERENCES Organization (org_id)
  , FOREIGN KEY (game_id) REFERENCES Game (game_id)
  , CHECK (start_date <= end_date)
  , CHECK (prize_pool >= 0)
);

CREATE TABLE Teams (
    team_id         INT           NOT NULL AUTO_INCREMENT
  , team_name       VARCHAR(255)  NOT NULL
  , region          VARCHAR(100)
  , founded_date    DATE
  , game_id         INT           NOT NULL
  , esports_org_id  INT
  , PRIMARY KEY (team_id)
  , UNIQUE (team_name)
  , FOREIGN KEY (game_id)        REFERENCES Game (game_id)
  , FOREIGN KEY (esports_org_id) REFERENCES EsportsOrg (esports_org_id)
);

CREATE TABLE Competitor (
      competitor_id    INT                    NOT NULL AUTO_INCREMENT
    , competitor_type  ENUM('team', 'player') NOT NULL
    , team_id          INT
    , player_id        INT
    , PRIMARY KEY (competitor_id)
    , UNIQUE (team_id)
    , UNIQUE (player_id)
    , FOREIGN KEY (team_id)   REFERENCES Teams (team_id)
    , FOREIGN KEY (player_id) REFERENCES Players (player_id)
    , CHECK (
          (competitor_type = 'team'
              AND team_id IS NOT NULL
              AND player_id IS NULL)
       OR (competitor_type = 'player'
              AND player_id IS NOT NULL
              AND team_id IS NULL)
      )
);

/*
CREATE TABLE `Match` (
    match_id        INT           NOT NULL AUTO_INCREMENT
  , tournament_id   INT           NOT NULL
  , scheduled_time  DATETIME
  , team1_id        INT           NOT NULL
  , team2_id        INT           NOT NULL
  , winner_team_id  INT
  , final_score     VARCHAR(20)
  , PRIMARY KEY (match_id)
  , FOREIGN KEY (tournament_id)  REFERENCES Tournament (tournament_id)
  , FOREIGN KEY (team1_id)       REFERENCES Teams (team_id)
  , FOREIGN KEY (team2_id)       REFERENCES Teams (team_id)
  , FOREIGN KEY (winner_team_id) REFERENCES Teams (team_id)
  , CHECK (team1_id <> team2_id)
  , CHECK (winner_team_id IS NULL
        OR winner_team_id IN (team1_id, team2_id))
);
*/

CREATE TABLE `Match` (
      match_id        INT       NOT NULL AUTO_INCREMENT
    , tournament_id   INT       NOT NULL
    , scheduled_time  DATETIME
    , final_score     VARCHAR(20)
    , PRIMARY KEY (match_id)
    , FOREIGN KEY (tournament_id)
        REFERENCES Tournament (tournament_id)
);

CREATE TABLE Contracts (
    contract_id    INT                         NOT NULL AUTO_INCREMENT
  , org_id         INT                         NOT NULL
  , tournament_id  INT
  , party_type     ENUM('sponsor','creator')   NOT NULL
  , sponsor_id     INT
  , creator_id     INT
  , start_date     DATE
  , end_date       DATE
  , total_value    DECIMAL(12,2)
  , PRIMARY KEY (contract_id)
  , FOREIGN KEY (org_id)        REFERENCES Organization (org_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  , FOREIGN KEY (sponsor_id)    REFERENCES Sponsors (sponsor_id)
  , FOREIGN KEY (creator_id)    REFERENCES Creators (creator_id)
  , CHECK (start_date < end_date)
  , CHECK (total_value > 0)
  , CHECK (
        (party_type = 'sponsor' AND sponsor_id IS NOT NULL AND creator_id IS NULL)
     OR (party_type = 'creator' AND creator_id IS NOT NULL AND sponsor_id IS NULL))
);

CREATE TABLE Deliverables (
    deliverable_id  INT           NOT NULL AUTO_INCREMENT
  , contract_id     INT           NOT NULL
  , description     VARCHAR(500)  NOT NULL
  , type            VARCHAR(100)
  , due_date        DATE
  , status          VARCHAR(50)
  , click_count     INT           DEFAULT 0
  , PRIMARY KEY (deliverable_id)
  , FOREIGN KEY (contract_id) REFERENCES Contracts (contract_id)
  , CHECK (click_count >= 0)
);

CREATE TABLE Transactions (
    transaction_id  INT                          NOT NULL AUTO_INCREMENT
  , org_id          INT                          NOT NULL
  , tournament_id   INT
  , type            ENUM('revenue','expense')    NOT NULL
  , category        VARCHAR(100)
  , amount          DECIMAL(12,2)                NOT NULL
  , date            DATE
  , PRIMARY KEY (transaction_id)
  , FOREIGN KEY (org_id)        REFERENCES Organization (org_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  , CHECK (amount >= 0)
);

CREATE TABLE Payments (
    payment_id     INT                       NOT NULL AUTO_INCREMENT
  , payee_type     ENUM('staff','team')      NOT NULL
  , staff_user_id  INT
  , team_id        INT
  , tournament_id  INT                        NOT NULL
  , amount         DECIMAL(12,2)              NOT NULL
  , status         VARCHAR(50)
  , payment_date   DATE
  , PRIMARY KEY (payment_id)
  , FOREIGN KEY (staff_user_id) REFERENCES Users (user_id)
  , FOREIGN KEY (team_id)       REFERENCES Teams (team_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  , CHECK (amount > 0)
  , CHECK (
        (payee_type = 'staff' AND staff_user_id IS NOT NULL AND team_id IS NULL)
     OR (payee_type = 'team'  AND team_id IS NOT NULL AND staff_user_id IS NULL))
);



-- GROUP 3 JUNCTION TABLES (resolve the M:N relationships)

CREATE TABLE MatchParticipant (
      match_id       INT NOT NULL
    , competitor_id  INT NOT NULL
    , placement      INT
    , points         INT DEFAULT 0
    , PRIMARY KEY (match_id, competitor_id)
    , FOREIGN KEY (match_id)
        REFERENCES `Match` (match_id)
    , FOREIGN KEY (competitor_id)
        REFERENCES Competitor (competitor_id)
    , CHECK (placement IS NULL OR placement > 0)
    , CHECK (points >= 0)
);

CREATE TABLE Membership (              -- Users <-> Organization (M:N)
    user_id      INT   NOT NULL
  , org_id       INT   NOT NULL
  , role         VARCHAR(50)
  , joined_date  DATE  NOT NULL
  , left_date    DATE                  -- NULL = still an active member
  , PRIMARY KEY (user_id, org_id)
  , FOREIGN KEY (user_id) REFERENCES Users (user_id)
  , FOREIGN KEY (org_id)  REFERENCES Organization (org_id)
  , CHECK (left_date IS NULL OR left_date >= joined_date)
);

CREATE TABLE Registration (            -- Competitor <-> Tournament (M:N)
    competitor_id      INT   NOT NULL
  , tournament_id      INT   NOT NULL
  , registration_date  DATE
  , seed               INT
  , PRIMARY KEY (competitor_id, tournament_id)
  , FOREIGN KEY (competitor_id) REFERENCES Competitor (competitor_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  -- APP/TRIGGER: for a 'team' competitor, Teams.game_id must match the
  -- tournament's game_id; a 'player' competitor carries no game of its own
);

CREATE TABLE Roster (                  -- Players <-> Teams (M:N), with surrogate PK
    roster_id      INT   NOT NULL AUTO_INCREMENT
  , player_id      INT   NOT NULL
  , team_id        INT   NOT NULL
  , join_date      DATE
  , leave_date     DATE
  , salary         DECIMAL(12,2)
  , jersey_number  INT
  , PRIMARY KEY (roster_id)
  , FOREIGN KEY (player_id) REFERENCES Players (player_id)
  , FOREIGN KEY (team_id)   REFERENCES Teams (team_id)
  , UNIQUE (team_id, jersey_number)             -- jersey unique within a team
  , CHECK (join_date <= leave_date)
  , CHECK (salary >= 0)
  -- APP/TRIGGER: no player on two active teams at once
);

CREATE TABLE StaffAssignments (        -- Users <-> Tournament (M:N)
    user_id        INT   NOT NULL
  , tournament_id  INT   NOT NULL
  , staff_role     VARCHAR(100)
  , pay_amount     DECIMAL(12,2)
  , PRIMARY KEY (user_id, tournament_id)
  , FOREIGN KEY (user_id)       REFERENCES Users (user_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  , CHECK (pay_amount >= 0)
  -- APP/TRIGGER: no overlapping tournaments; user must belong to the running org
);

CREATE TABLE PlayerMatchStats (        -- Players <-> Match (M:N)
    player_id  INT   NOT NULL
  , match_id   INT   NOT NULL
  , kills      INT   DEFAULT 0
  , deaths     INT   DEFAULT 0
  , assists    INT   DEFAULT 0
  , score      INT   DEFAULT 0
  , PRIMARY KEY (player_id, match_id)
  , FOREIGN KEY (player_id) REFERENCES Players (player_id)
  , FOREIGN KEY (match_id)  REFERENCES `Match` (match_id)
  , CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0 AND score >= 0)
  -- APP/TRIGGER: no player in two matches at the same time
);

CREATE TABLE CreatorAssignment (       -- Creators <-> Tournament (M:N)
    creator_id     INT   NOT NULL
  , tournament_id  INT   NOT NULL
  , role           VARCHAR(100)
  , rate           DECIMAL(12,2)
  , status         VARCHAR(50)
  , PRIMARY KEY (creator_id, tournament_id)
  , FOREIGN KEY (creator_id)    REFERENCES Creators (creator_id)
  , FOREIGN KEY (tournament_id) REFERENCES Tournament (tournament_id)
  , CHECK (rate IS NULL OR rate >= 0)
);

CREATE TABLE StaffMatches (            -- Users <-> Match (M:N)
    user_id   INT   NOT NULL
  , match_id  INT   NOT NULL
  , role      VARCHAR(100)
  , PRIMARY KEY (user_id, match_id)
  , FOREIGN KEY (user_id)  REFERENCES Users (user_id)
  , FOREIGN KEY (match_id) REFERENCES `Match` (match_id)
  -- APP/TRIGGER: user cannot work matches with overlapping times
);

CREATE TABLE CreatorMatches (          -- Creators <-> Match (M:N)
    creator_id  INT   NOT NULL
  , match_id    INT   NOT NULL
  , PRIMARY KEY (creator_id, match_id)
  , FOREIGN KEY (creator_id) REFERENCES Creators (creator_id)
  , FOREIGN KEY (match_id)   REFERENCES `Match` (match_id)
  -- APP/TRIGGER: no overlapping match times; at least 1 creator per match
);
