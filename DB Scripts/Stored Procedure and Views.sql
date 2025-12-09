CREATE OR ALTER PROCEDURE betting.usp_GenerateValueBets_Moneyline_MarketConsensus
(
    @FromDateUtc DATE,
    @ToDateUtc   DATE
)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Create ModelRun
    ------------------------------------------------------------
    DECLARE @ModelRunId BIGINT;

    EXEC betting.usp_CreateModelRun
        @ModelName      = N'MarketConsensusML',
        @ModelVersion   = N'1.0.0',
        @ModelTypeCode  = N'MONEYLINE',
        @RunType        = N'Live',
        @FromDateUtc    = @FromDateUtc,
        @ToDateUtc      = @ToDateUtc,
        @ParametersJson = NULL,
        @ModelRunId     = @ModelRunId OUTPUT;

    ------------------------------------------------------------
    -- 2. Drop temp table (defensive) BEFORE CTE
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Temp_Bets') IS NOT NULL
        DROP TABLE #Temp_Bets;

    ------------------------------------------------------------
    -- 3. Build input CTEs (moneyline only, date-filtered)
    --    and compute into #Temp_Bets
    ------------------------------------------------------------
    ;WITH MoneylineMarkets AS
    (
        SELECT
            vm.MarketOutcomeId,
            vm.MarketId,
            vm.GameId,
            vm.MarketTypeCode,
            vm.OutcomeCode,
            vm.GameDateUtc
        FROM betting.vMarketsExpanded vm
        WHERE vm.MarketTypeCode = 'MONEYLINE'
          AND vm.GameDateUtc >= @FromDateUtc
          AND vm.GameDateUtc <= @ToDateUtc
    ),
    LatestOdds AS
    (
        SELECT
            mm.MarketOutcomeId,
            lo.ProviderId,
            lo.AmericanOdds,
            lo.DecimalOdds,
            lo.ImpliedProbability
        FROM MoneylineMarkets mm
        JOIN betting.vLatestOddsPerOutcome lo
             ON mm.MarketOutcomeId = lo.MarketOutcomeId
    ),
    MarketConsensusRaw AS
    (
        SELECT
            lo.MarketOutcomeId,
            lo.ProviderId,
            lo.AmericanOdds,
            lo.DecimalOdds,
            lo.ImpliedProbability,
            AVG(lo2.DecimalOdds) AS AvgDecimalOtherProviders
        FROM LatestOdds lo
        JOIN LatestOdds lo2
             ON lo2.MarketOutcomeId = lo.MarketOutcomeId
            AND lo2.ProviderId <> lo.ProviderId
        GROUP BY
            lo.MarketOutcomeId,
            lo.ProviderId,
            lo.AmericanOdds,
            lo.DecimalOdds,
            lo.ImpliedProbability
    )
    SELECT
        mc.MarketOutcomeId,
        mc.ProviderId,
        mc.AmericanOdds,
        mc.ImpliedProbability,
        mc.AvgDecimalOtherProviders       AS FairDecimalOdds,
        mp.ModelProbability,
        betting.fn_CalcEdge(mp.ModelProbability, mc.ImpliedProbability) AS Edge,
        betting.fn_ClassifyRisk(
            betting.fn_CalcEdge(mp.ModelProbability, mc.ImpliedProbability)
        ) AS RiskLevel
    INTO #Temp_Bets
    FROM MarketConsensusRaw mc
    CROSS APPLY
    (
        SELECT
            CASE
                WHEN mc.AvgDecimalOtherProviders IS NULL OR mc.AvgDecimalOtherProviders = 0
                    THEN NULL
                ELSE CONVERT(DECIMAL(6,5), 1.0 / mc.AvgDecimalOtherProviders)
            END AS ModelProbability
    ) mp;

    -- If nothing to process, just finish the ModelRun and exit
    IF NOT EXISTS (SELECT 1 FROM #Temp_Bets)
    BEGIN
        UPDATE betting.ModelRun
        SET FinishedUtc = SYSUTCDATETIME()
        WHERE ModelRunId = @ModelRunId;

        RETURN;
    END;

    ------------------------------------------------------------
    -- 4. Insert into ModelPrediction, capture IDs into #Temp_BetPredictions
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Temp_BetPredictions') IS NOT NULL
        DROP TABLE #Temp_BetPredictions;

    CREATE TABLE #Temp_BetPredictions
    (
        ModelPredictionId BIGINT,
        MarketOutcomeId   BIGINT,  -- if your real column is INT, change this to INT
        ProviderId        BIGINT
    );

    INSERT INTO betting.ModelPrediction
    (
        ModelRunId,
        MarketOutcomeId,
        ProviderId,
        WinProbability,
        FairDecimalOdds,
        FairAmericanOdds
    )
    OUTPUT
        INSERTED.ModelPredictionId,
        INSERTED.MarketOutcomeId,
        INSERTED.ProviderId
    INTO #Temp_BetPredictions (ModelPredictionId, MarketOutcomeId, ProviderId)
    SELECT
        @ModelRunId,
        tb.MarketOutcomeId,
        tb.ProviderId,
        tb.ModelProbability,
        tb.FairDecimalOdds,
        NULL -- FairAmericanOdds (optional)
    FROM #Temp_Bets tb;

    ------------------------------------------------------------
    -- 5. Insert into BetRecommendation
    ------------------------------------------------------------
    INSERT INTO betting.BetRecommendation
    (
        ModelPredictionId,
        MarketOutcomeId,
        ProviderId,
        GameId,
        PlayerId,
        MarketTypeId,
        LineValue,
        AmericanOdds,
        ImpliedProbability,
        ModelProbability,
        Edge,
        RiskLevel
    )
    SELECT
        bp.ModelPredictionId,
        bp.MarketOutcomeId,
        bp.ProviderId,
        vm.GameId,
        vm.PlayerId,
        mt.MarketTypeId,
        vm.LineValue,
        tb.AmericanOdds,
        tb.ImpliedProbability,
        tb.ModelProbability,
        tb.Edge,
        tb.RiskLevel
    FROM #Temp_BetPredictions bp
    JOIN #Temp_Bets tb
         ON bp.MarketOutcomeId = tb.MarketOutcomeId
        AND bp.ProviderId      = tb.ProviderId
    JOIN betting.vMarketsExpanded vm
         ON bp.MarketOutcomeId = vm.MarketOutcomeId
    JOIN betting.MarketType mt
         ON vm.MarketTypeCode = mt.Code
    WHERE vm.MarketTypeCode = 'MONEYLINE';

    ------------------------------------------------------------
    -- 6. Mark ModelRun finished
    ------------------------------------------------------------
    UPDATE betting.ModelRun
    SET FinishedUtc = SYSUTCDATETIME()
    WHERE ModelRunId = @ModelRunId;
END;
GO
