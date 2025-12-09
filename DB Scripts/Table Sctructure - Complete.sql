------------------------------------------------------------
-- 0. Create schema
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'betting')
    EXEC('CREATE SCHEMA betting');
GO

/*==========================================================
  1. CORE LOOKUPS: SPORT, LEAGUE, TEAM, PLAYER
==========================================================*/

------------------------------------------------------------
-- Sport
------------------------------------------------------------
IF OBJECT_ID('betting.Sport', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Sport
    (
        SportId        INT IDENTITY(1,1) CONSTRAINT PK_Sport PRIMARY KEY CLUSTERED,
        Name           NVARCHAR(100) NOT NULL,
        Code           NVARCHAR(20)  NOT NULL,   -- e.g. "BASKETBALL"
        CONSTRAINT UX_Sport_Code UNIQUE (Code)
    );
END;
GO

------------------------------------------------------------
-- League
------------------------------------------------------------
IF OBJECT_ID('betting.League', 'U') IS NULL
BEGIN
    CREATE TABLE betting.League
    (
        LeagueId       INT IDENTITY(1,1) CONSTRAINT PK_League PRIMARY KEY CLUSTERED,
        SportId        INT           NOT NULL,
        Name           NVARCHAR(100) NOT NULL,
        Code           NVARCHAR(20)  NOT NULL,   -- e.g. "NBA"
        TimeZone       NVARCHAR(50)  NULL,       -- e.g. "America/New_York"

        CONSTRAINT UX_League_Code UNIQUE (Code),
        CONSTRAINT FK_League_Sport
            FOREIGN KEY (SportId) REFERENCES betting.Sport (SportId)
    );
END;
GO

------------------------------------------------------------
-- Team
------------------------------------------------------------
IF OBJECT_ID('betting.Team', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Team
    (
        TeamId         INT IDENTITY(1,1) CONSTRAINT PK_Team PRIMARY KEY CLUSTERED,
        LeagueId       INT            NOT NULL,
        Name           NVARCHAR(100)  NOT NULL,    -- "Boston Celtics"
        Abbreviation   NVARCHAR(10)   NOT NULL,    -- "BOS"
        ExternalRef    NVARCHAR(100)  NULL,        -- ID from odds providers
        IsActive       BIT            NOT NULL CONSTRAINT DF_Team_IsActive DEFAULT (1),

        CONSTRAINT UX_Team_League_Abbreviation UNIQUE (LeagueId, Abbreviation),
        CONSTRAINT UX_Team_League_Name         UNIQUE (LeagueId, Name),
        CONSTRAINT FK_Team_League
            FOREIGN KEY (LeagueId) REFERENCES betting.League (LeagueId)
    );
END;
GO

------------------------------------------------------------
-- Player
------------------------------------------------------------
IF OBJECT_ID('betting.Player', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Player
    (
        PlayerId       INT IDENTITY(1,1) CONSTRAINT PK_Player PRIMARY KEY CLUSTERED,
        TeamId         INT            NOT NULL,         -- current team
        FullName       NVARCHAR(120)  NOT NULL,
        FirstName      NVARCHAR(60)   NULL,
        LastName       NVARCHAR(60)   NULL,
        Position       NVARCHAR(10)   NULL,            -- "G", "F", "C", etc.
        ExternalRef    NVARCHAR(100)  NULL,            -- provider / stats API ID
        IsActive       BIT            NOT NULL CONSTRAINT DF_Player_IsActive DEFAULT (1),

        CONSTRAINT FK_Player_Team
            FOREIGN KEY (TeamId) REFERENCES betting.Team (TeamId)
    );
END;
GO

/*==========================================================
  2. GAMES & RESULTS
==========================================================*/

------------------------------------------------------------
-- Game
------------------------------------------------------------
IF OBJECT_ID('betting.Game', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Game
    (
        GameId         BIGINT IDENTITY(1,1) CONSTRAINT PK_Game PRIMARY KEY CLUSTERED,
        LeagueId       INT            NOT NULL,
        Season         NVARCHAR(20)   NOT NULL,       -- e.g. "2024-2025"
        GameDateUtc    DATE           NOT NULL,       -- date portion only
        StartTimeUtc   DATETIME2(3)   NOT NULL,
        HomeTeamId     INT            NOT NULL,
        AwayTeamId     INT            NOT NULL,
        Status         NVARCHAR(20)   NOT NULL CONSTRAINT DF_Game_Status DEFAULT ('Scheduled'),
        ExternalRef    NVARCHAR(100)  NULL,           -- provider game ID

        CONSTRAINT FK_Game_League
            FOREIGN KEY (LeagueId)   REFERENCES betting.League (LeagueId),
        CONSTRAINT FK_Game_Home_Team
            FOREIGN KEY (HomeTeamId) REFERENCES betting.Team   (TeamId),
        CONSTRAINT FK_Game_Away_Team
            FOREIGN KEY (AwayTeamId) REFERENCES betting.Team   (TeamId),

        CONSTRAINT UX_Game_League_Date_Teams UNIQUE
        (
            LeagueId, GameDateUtc, HomeTeamId, AwayTeamId
        )
    );
END;
GO

------------------------------------------------------------
-- GameResult
------------------------------------------------------------
IF OBJECT_ID('betting.GameResult', 'U') IS NULL
BEGIN
    CREATE TABLE betting.GameResult
    (
        GameResultId   BIGINT IDENTITY(1,1) CONSTRAINT PK_GameResult PRIMARY KEY CLUSTERED,
        GameId         BIGINT       NOT NULL,
        HomeScore      SMALLINT     NOT NULL,
        AwayScore      SMALLINT     NOT NULL,
        FinalStatus    NVARCHAR(20) NOT NULL,       -- "Final", "Cancelled", etc.
        IsOvertime     BIT          NOT NULL CONSTRAINT DF_GameResult_IsOvertime DEFAULT (0),
        UpdatedUtc     DATETIME2(3) NOT NULL CONSTRAINT DF_GameResult_UpdatedUtc DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_GameResult_Game
            FOREIGN KEY (GameId) REFERENCES betting.Game (GameId),
        CONSTRAINT UX_GameResult_Game UNIQUE (GameId)
    );
END;
GO

------------------------------------------------------------
-- PlayerGameStats
------------------------------------------------------------
IF OBJECT_ID('betting.PlayerGameStats', 'U') IS NULL
BEGIN
    CREATE TABLE betting.PlayerGameStats
    (
        PlayerGameStatsId BIGINT IDENTITY(1,1) CONSTRAINT PK_PlayerGameStats PRIMARY KEY CLUSTERED,
        GameId            BIGINT       NOT NULL,
        PlayerId          INT          NOT NULL,
        Minutes           DECIMAL(5,2) NULL,
        Points            SMALLINT     NULL,
        Rebounds          SMALLINT     NULL,
        Assists           SMALLINT     NULL,
        Blocks            SMALLINT     NULL,
        Steals            SMALLINT     NULL,
        Turnovers         SMALLINT     NULL,
        CreatedUtc        DATETIME2(3) NOT NULL CONSTRAINT DF_PlayerGameStats_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        UpdatedUtc        DATETIME2(3) NOT NULL CONSTRAINT DF_PlayerGameStats_UpdatedUtc DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_PlayerGameStats_Game
            FOREIGN KEY (GameId)   REFERENCES betting.Game   (GameId),
        CONSTRAINT FK_PlayerGameStats_Player
            FOREIGN KEY (PlayerId) REFERENCES betting.Player (PlayerId),

        CONSTRAINT UX_PlayerGameStats_Game_Player UNIQUE (GameId, PlayerId)
    );
END;
GO

/*==========================================================
  3. MARKET TYPES, STAT TYPES, PROVIDERS
==========================================================*/

------------------------------------------------------------
-- MarketType
------------------------------------------------------------
IF OBJECT_ID('betting.MarketType', 'U') IS NULL
BEGIN
    CREATE TABLE betting.MarketType
    (
        MarketTypeId   INT IDENTITY(1,1) CONSTRAINT PK_MarketType PRIMARY KEY CLUSTERED,
        Code           NVARCHAR(40)  NOT NULL,     -- "MONEYLINE", "SPREAD", etc.
        Description    NVARCHAR(200) NOT NULL,

        CONSTRAINT UX_MarketType_Code UNIQUE (Code)
    );
END;
GO

------------------------------------------------------------
-- StatType
------------------------------------------------------------
IF OBJECT_ID('betting.StatType', 'U') IS NULL
BEGIN
    CREATE TABLE betting.StatType
    (
        StatTypeId     INT IDENTITY(1,1) CONSTRAINT PK_StatType PRIMARY KEY CLUSTERED,
        Code           NVARCHAR(40)  NOT NULL,      -- "POINTS", "REBOUNDS", "ASSISTS"
        Description    NVARCHAR(200) NOT NULL,

        CONSTRAINT UX_StatType_Code UNIQUE (Code)
    );
END;
GO

------------------------------------------------------------
-- OddsProvider
------------------------------------------------------------
IF OBJECT_ID('betting.OddsProvider', 'U') IS NULL
BEGIN
    CREATE TABLE betting.OddsProvider
    (
        ProviderId     BIGINT IDENTITY(1,1) CONSTRAINT PK_OddsProvider PRIMARY KEY CLUSTERED,
        Name           NVARCHAR(100) NOT NULL,   -- "Bet365", "DraftKings"
        Code           NVARCHAR(50)  NULL,       -- short code
        ApiIdentifier  NVARCHAR(100) NULL,       -- mapping to external systems
        IsActive       BIT           NOT NULL CONSTRAINT DF_OddsProvider_IsActive DEFAULT (1),

        CONSTRAINT UX_OddsProvider_Name UNIQUE (Name),
        CONSTRAINT UX_OddsProvider_Code UNIQUE (Code)
    );
END;
GO

/*==========================================================
  4. MARKETS, OUTCOMES, ODDS SNAPSHOTS
==========================================================*/

------------------------------------------------------------
-- Market
------------------------------------------------------------
IF OBJECT_ID('betting.Market', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Market
    (
        MarketId       BIGINT IDENTITY(1,1) CONSTRAINT PK_Market PRIMARY KEY CLUSTERED,
        GameId         BIGINT       NOT NULL,
        MarketTypeId   INT          NOT NULL,
        StatTypeId     INT          NULL,        -- only for player props
        PlayerId       INT          NULL,        -- NULL for game-level markets
        Period         NVARCHAR(20) NOT NULL CONSTRAINT DF_Market_Period DEFAULT ('FULL_GAME'),
        LineValue      DECIMAL(8,3) NULL,        -- spread line, total, prop line, etc.
        CreatedUtc     DATETIME2(3) NOT NULL CONSTRAINT DF_Market_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        IsActive       BIT          NOT NULL CONSTRAINT DF_Market_IsActive DEFAULT (1),

        CONSTRAINT FK_Market_Game
            FOREIGN KEY (GameId)       REFERENCES betting.Game      (GameId),
        CONSTRAINT FK_Market_MarketType
            FOREIGN KEY (MarketTypeId) REFERENCES betting.MarketType(MarketTypeId),
        CONSTRAINT FK_Market_StatType
            FOREIGN KEY (StatTypeId)   REFERENCES betting.StatType  (StatTypeId),
        CONSTRAINT FK_Market_Player
            FOREIGN KEY (PlayerId)     REFERENCES betting.Player    (PlayerId),

        CONSTRAINT UX_Market_UniqueKey UNIQUE
        (
            GameId,
            MarketTypeId,
            StatTypeId,
            PlayerId,
            Period,
            LineValue
        )
    );
END;
GO

------------------------------------------------------------
-- MarketOutcome
------------------------------------------------------------
IF OBJECT_ID('betting.MarketOutcome', 'U') IS NULL
BEGIN
    CREATE TABLE betting.MarketOutcome
    (
        MarketOutcomeId BIGINT IDENTITY(1,1) CONSTRAINT PK_MarketOutcome PRIMARY KEY CLUSTERED,
        MarketId        BIGINT       NOT NULL,
        OutcomeCode     NVARCHAR(20) NOT NULL,      -- "HOME", "AWAY", "OVER", "UNDER"
        Description     NVARCHAR(200) NOT NULL,     -- "Home ML", "Over 216.5", etc.
        SortOrder       TINYINT       NOT NULL CONSTRAINT DF_MarketOutcome_SortOrder DEFAULT (1),

        CONSTRAINT FK_MarketOutcome_Market
            FOREIGN KEY (MarketId) REFERENCES betting.Market (MarketId),

        CONSTRAINT UX_MarketOutcome_Market_Outcome UNIQUE (MarketId, OutcomeCode)
    );
END;
GO

------------------------------------------------------------
-- OddsSnapshot
------------------------------------------------------------
IF OBJECT_ID('betting.OddsSnapshot', 'U') IS NULL
BEGIN
    CREATE TABLE betting.OddsSnapshot
    (
        OddsSnapshotId     BIGINT IDENTITY(1,1) CONSTRAINT PK_OddsSnapshot PRIMARY KEY CLUSTERED,
        MarketOutcomeId    BIGINT       NOT NULL,
        ProviderId         BIGINT       NOT NULL,
        SnapshotTimeUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_OddsSnapshot_SnapshotTimeUtc DEFAULT (SYSUTCDATETIME()),
        AmericanOdds       INT          NOT NULL,        -- e.g. -110, +150
        DecimalOdds        DECIMAL(10,4) NULL,
        ImpliedProbability DECIMAL(6,5)  NULL,
        Source             NVARCHAR(50)  NULL,           -- "TheOddsAPI", etc.

        CONSTRAINT FK_OddsSnapshot_MarketOutcome
            FOREIGN KEY (MarketOutcomeId) REFERENCES betting.MarketOutcome (MarketOutcomeId),
        CONSTRAINT FK_OddsSnapshot_OddsProvider
            FOREIGN KEY (ProviderId)      REFERENCES betting.OddsProvider  (ProviderId)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OddsSnapshot_MarketOutcome_Provider_Time'
               AND object_id = OBJECT_ID('betting.OddsSnapshot'))
BEGIN
    CREATE INDEX IX_OddsSnapshot_MarketOutcome_Provider_Time
    ON betting.OddsSnapshot (MarketOutcomeId, ProviderId, SnapshotTimeUtc DESC);
END;
GO

/*==========================================================
  5. MODELS, RUNS, PREDICTIONS, VALUE BETS
==========================================================*/

------------------------------------------------------------
-- Model
------------------------------------------------------------
IF OBJECT_ID('betting.Model', 'U') IS NULL
BEGIN
    CREATE TABLE betting.Model
    (
        ModelId        INT IDENTITY(1,1) CONSTRAINT PK_Model PRIMARY KEY CLUSTERED,
        Name           NVARCHAR(100) NOT NULL,   -- "MarketConsensusML"
        Version        NVARCHAR(50)  NOT NULL,   -- "1.0.0"
        ModelTypeCode  NVARCHAR(40)  NOT NULL,   -- "MONEYLINE", "PLAYER_POINTS", etc.
        Description    NVARCHAR(4000) NULL,
        IsActive       BIT           NOT NULL CONSTRAINT DF_Model_IsActive DEFAULT (1),

        CONSTRAINT UX_Model_Name_Version UNIQUE (Name, Version)
    );
END;
GO

------------------------------------------------------------
-- ModelRun
------------------------------------------------------------
IF OBJECT_ID('betting.ModelRun', 'U') IS NULL
BEGIN
    CREATE TABLE betting.ModelRun
    (
        ModelRunId      BIGINT IDENTITY(1,1) CONSTRAINT PK_ModelRun PRIMARY KEY CLUSTERED,
        ModelId         INT           NOT NULL,
        RunType         NVARCHAR(20)  NOT NULL,      -- "Live", "Backtest"
        FromDateUtc     DATE          NULL,
        ToDateUtc       DATE          NULL,
        StartedUtc      DATETIME2(3)  NOT NULL CONSTRAINT DF_ModelRun_StartedUtc DEFAULT (SYSUTCDATETIME()),
        FinishedUtc     DATETIME2(3)  NULL,
        ParametersJson  NVARCHAR(MAX) NULL,

        CONSTRAINT FK_ModelRun_Model
            FOREIGN KEY (ModelId) REFERENCES betting.Model (ModelId)
    );
END;
GO

------------------------------------------------------------
-- ModelPrediction
------------------------------------------------------------
IF OBJECT_ID('betting.ModelPrediction', 'U') IS NULL
BEGIN
    CREATE TABLE betting.ModelPrediction
    (
        ModelPredictionId BIGINT IDENTITY(1,1) CONSTRAINT PK_ModelPrediction PRIMARY KEY CLUSTERED,
        ModelRunId        BIGINT       NOT NULL,
        MarketOutcomeId   BIGINT       NOT NULL,
        ProviderId        BIGINT       NULL,         -- if model is provider-specific
        WinProbability    DECIMAL(6,5) NOT NULL,     -- 0 to 1
        FairDecimalOdds   DECIMAL(10,4) NULL,
        FairAmericanOdds  INT          NULL,
        CreatedUtc        DATETIME2(3) NOT NULL CONSTRAINT DF_ModelPrediction_CreatedUtc DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_ModelPrediction_ModelRun
            FOREIGN KEY (ModelRunId)      REFERENCES betting.ModelRun      (ModelRunId),
        CONSTRAINT FK_ModelPrediction_MarketOutcome
            FOREIGN KEY (MarketOutcomeId) REFERENCES betting.MarketOutcome (MarketOutcomeId),
        CONSTRAINT FK_ModelPrediction_OddsProvider
            FOREIGN KEY (ProviderId)      REFERENCES betting.OddsProvider  (ProviderId),

        CONSTRAINT UX_ModelPrediction_Run_Outcome_Provider UNIQUE
        (
            ModelRunId,
            MarketOutcomeId,
            ProviderId
        )
    );
END;
GO

------------------------------------------------------------
-- BetRecommendation
------------------------------------------------------------
IF OBJECT_ID('betting.BetRecommendation', 'U') IS NULL
BEGIN
    CREATE TABLE betting.BetRecommendation
    (
        BetRecommendationId BIGINT IDENTITY(1,1) CONSTRAINT PK_BetRecommendation PRIMARY KEY CLUSTERED,
        ModelPredictionId   BIGINT       NOT NULL,
        MarketOutcomeId     BIGINT       NOT NULL,
        ProviderId          BIGINT       NOT NULL,
        GameId              BIGINT       NOT NULL,
        PlayerId            INT          NULL,
        MarketTypeId        INT          NOT NULL,
        LineValue           DECIMAL(8,3) NULL,
        AmericanOdds        INT          NOT NULL,
        ImpliedProbability  DECIMAL(6,5) NOT NULL,
        ModelProbability    DECIMAL(6,5) NOT NULL,
        Edge                DECIMAL(7,6) NOT NULL,    -- e.g. 0.050000 for 5% edge
        RiskLevel           NVARCHAR(20) NOT NULL,    -- "Low", "Medium", "High", "Negative"
        CreatedUtc          DATETIME2(3) NOT NULL CONSTRAINT DF_BetRecommendation_CreatedUtc DEFAULT (SYSUTCDATETIME()),
        IsActive            BIT          NOT NULL CONSTRAINT DF_BetRecommendation_IsActive DEFAULT (1),

        CONSTRAINT FK_BetRecommendation_ModelPrediction
            FOREIGN KEY (ModelPredictionId) REFERENCES betting.ModelPrediction (ModelPredictionId),
        CONSTRAINT FK_BetRecommendation_MarketOutcome
            FOREIGN KEY (MarketOutcomeId) REFERENCES betting.MarketOutcome (MarketOutcomeId),
        CONSTRAINT FK_BetRecommendation_OddsProvider
            FOREIGN KEY (ProviderId)      REFERENCES betting.OddsProvider  (ProviderId),
        CONSTRAINT FK_BetRecommendation_Game
            FOREIGN KEY (GameId)          REFERENCES betting.Game          (GameId),
        CONSTRAINT FK_BetRecommendation_Player
            FOREIGN KEY (PlayerId)        REFERENCES betting.Player        (PlayerId),
        CONSTRAINT FK_BetRecommendation_MarketType
            FOREIGN KEY (MarketTypeId)    REFERENCES betting.MarketType    (MarketTypeId),

        CONSTRAINT UX_BetRecommendation_Prediction_Outcome_Provider UNIQUE
        (
            ModelPredictionId,
            MarketOutcomeId,
            ProviderId
        )
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BetRecommendation_Date_MarketType'
               AND object_id = OBJECT_ID('betting.BetRecommendation'))
BEGIN
    CREATE INDEX IX_BetRecommendation_Date_MarketType
    ON betting.BetRecommendation (CreatedUtc, MarketTypeId, Edge DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BetRecommendation_Game'
               AND object_id = OBJECT_ID('betting.BetRecommendation'))
BEGIN
    CREATE INDEX IX_BetRecommendation_Game
    ON betting.BetRecommendation (GameId, MarketTypeId, Edge DESC);
END;
GO

------------------------------------------------------------
-- Index on Game by date (useful for API/filtering)
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Game_GameDateUtc'
               AND object_id = OBJECT_ID('betting.Game'))
BEGIN
    CREATE INDEX IX_Game_GameDateUtc
    ON betting.Game (GameDateUtc, LeagueId);
END;
GO

/*==========================================================
  6. BET TICKETS
==========================================================*/

------------------------------------------------------------
-- BetTicket
------------------------------------------------------------
IF OBJECT_ID('betting.BetTicket', 'U') IS NULL
BEGIN
    CREATE TABLE betting.BetTicket
    (
        BetTicketId     BIGINT IDENTITY(1,1) CONSTRAINT PK_BetTicket PRIMARY KEY CLUSTERED,
        TicketRef       UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_BetTicket_TicketRef DEFAULT (NEWID()),
        PlacedUtc       DATETIME2(3)     NOT NULL CONSTRAINT DF_BetTicket_PlacedUtc DEFAULT (SYSUTCDATETIME()),
        StakeAmount     DECIMAL(12,2)    NOT NULL,
        CurrencyCode    CHAR(3)          NOT NULL CONSTRAINT DF_BetTicket_CurrencyCode DEFAULT ('USD'),
        StrategyTag     NVARCHAR(50)     NULL,           -- "MainBankroll", "Test", etc.
        Source          NVARCHAR(30)     NULL,           -- "Manual", "Bot"
        Status          NVARCHAR(20)     NOT NULL CONSTRAINT DF_BetTicket_Status DEFAULT ('Pending'),
        Notes           NVARCHAR(1000)   NULL,

        CONSTRAINT UX_BetTicket_TicketRef UNIQUE (TicketRef)
    );
END;
GO

------------------------------------------------------------
-- BetTicketLeg
------------------------------------------------------------
IF OBJECT_ID('betting.BetTicketLeg', 'U') IS NULL
BEGIN
    CREATE TABLE betting.BetTicketLeg
    (
        BetTicketLegId    BIGINT IDENTITY(1,1) CONSTRAINT PK_BetTicketLeg PRIMARY KEY CLUSTERED,
        BetTicketId       BIGINT        NOT NULL,
        BetRecommendationId BIGINT      NULL,        -- if created from recommendation
        MarketOutcomeId   BIGINT        NOT NULL,
        ProviderId        BIGINT        NOT NULL,
        AmericanOdds      INT           NOT NULL,
        LineValue         DECIMAL(8,3)  NULL,
        StakeAmount       DECIMAL(12,2) NULL,        -- per-leg stake; NULL if full-stake at ticket level
        Status            NVARCHAR(20)  NOT NULL CONSTRAINT DF_BetTicketLeg_Status DEFAULT ('Pending'),
        PayoutAmount      DECIMAL(12,2) NULL,

        CONSTRAINT FK_BetTicketLeg_BetTicket
            FOREIGN KEY (BetTicketId)        REFERENCES betting.BetTicket        (BetTicketId),
        CONSTRAINT FK_BetTicketLeg_BetRecommendation
            FOREIGN KEY (BetRecommendationId) REFERENCES betting.BetRecommendation (BetRecommendationId),
        CONSTRAINT FK_BetTicketLeg_MarketOutcome
            FOREIGN KEY (MarketOutcomeId)    REFERENCES betting.MarketOutcome    (MarketOutcomeId),
        CONSTRAINT FK_BetTicketLeg_OddsProvider
            FOREIGN KEY (ProviderId)         REFERENCES betting.OddsProvider     (ProviderId)
    );
END;
GO

/*==========================================================
  7. SEED DATA (BASIC)
==========================================================*/

-- Sport: Basketball
IF NOT EXISTS (SELECT 1 FROM betting.Sport WHERE Code = 'BASKETBALL')
BEGIN
    INSERT INTO betting.Sport (Name, Code)
    VALUES ('Basketball', 'BASKETBALL');
END;
GO

-- League: NBA
IF NOT EXISTS (SELECT 1 FROM betting.League WHERE Code = 'NBA')
BEGIN
    DECLARE @SportId_Basketball INT =
        (SELECT SportId FROM betting.Sport WHERE Code = 'BASKETBALL');

    INSERT INTO betting.League (SportId, Name, Code, TimeZone)
    VALUES (@SportId_Basketball, 'National Basketball Association', 'NBA', 'America/New_York');
END;
GO

-- MarketType seeds
IF NOT EXISTS (SELECT 1 FROM betting.MarketType WHERE Code = 'MONEYLINE')
BEGIN
    INSERT INTO betting.MarketType (Code, Description)
    VALUES
        ('MONEYLINE',      'Game moneyline'),
        ('SPREAD',         'Game spread'),
        ('TOTAL_POINTS',   'Game total points'),
        ('PLAYER_POINTS',  'Player points props'),
        ('PLAYER_REBOUNDS','Player rebounds props'),
        ('PLAYER_ASSISTS', 'Player assists props');
END;
GO

-- StatType seeds
IF NOT EXISTS (SELECT 1 FROM betting.StatType WHERE Code = 'POINTS')
BEGIN
    INSERT INTO betting.StatType (Code, Description)
    VALUES
        ('POINTS',   'Player points'),
        ('REBOUNDS', 'Player rebounds'),
        ('ASSISTS',  'Player assists');
END;
GO
