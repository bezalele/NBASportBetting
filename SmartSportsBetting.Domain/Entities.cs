using SmartSportsBetting.Domain.Entities;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartSportsBetting.Domain.Entities
{
    // -----------------------------
    // Core reference tables
    // -----------------------------

    [Table("Sport", Schema = "betting")]
    public class Sport
    {
        [Key]
        public int SportId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(20)]
        public string Code { get; set; } = string.Empty;   // e.g. "BASKETBALL"

        public ICollection<League> Leagues { get; set; } = new List<League>();
    }

    [Table("League", Schema = "betting")]
    public class League
    {
        [Key]
        public int LeagueId { get; set; }

        public int SportId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(20)]
        public string Code { get; set; } = string.Empty;   // e.g. "NBA"

        [MaxLength(50)]
        public string? TimeZone { get; set; }              // "America/New_York"

        public Sport? Sport { get; set; }
        public ICollection<Team> Teams { get; set; } = new List<Team>();
        public ICollection<Game> Games { get; set; } = new List<Game>();
    }

    [Table("Team", Schema = "betting")]
    public class Team
    {
        [Key]
        public int TeamId { get; set; }

        public int LeagueId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;      // "Boston Celtics"

        [Required, MaxLength(10)]
        public string Abbreviation { get; set; } = string.Empty; // "BOS"

        [MaxLength(100)]
        public string? ExternalRef { get; set; }

        public bool IsActive { get; set; }

        public League? League { get; set; }
        public ICollection<Game> HomeGames { get; set; } = new List<Game>();
        public ICollection<Game> AwayGames { get; set; } = new List<Game>();
        public ICollection<Player> Players { get; set; } = new List<Player>();
        public ICollection<TeamRating> TeamRatings { get; set; } = new List<TeamRating>();
    }

    [Table("Player", Schema = "betting")]
    public class Player
    {
        [Key]
        public int PlayerId { get; set; }

        public int TeamId { get; set; }

        [Required, MaxLength(120)]
        public string FullName { get; set; } = string.Empty;

        [MaxLength(60)]
        public string? FirstName { get; set; }

        [MaxLength(60)]
        public string? LastName { get; set; }

        [MaxLength(10)]
        public string? Position { get; set; }                 // "G", "F", "C"

        [MaxLength(100)]
        public string? ExternalRef { get; set; }

        public bool IsActive { get; set; }

        public Team? Team { get; set; }
        public ICollection<PlayerGameStats> PlayerGameStats { get; set; } = new List<PlayerGameStats>();
        public ICollection<Market> Markets { get; set; } = new List<Market>(); // player props
        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
    }

    // -----------------------------
    // Games and stats
    // -----------------------------

    [Table("Game", Schema = "betting")]
    public class Game
    {
        [Key]
        public long GameId { get; set; }

        public int LeagueId { get; set; }

        [Required, MaxLength(20)]
        public string Season { get; set; } = string.Empty;    // "2024-2025"

        public DateTime GameDateUtc { get; set; }
        public DateTime StartTimeUtc { get; set; }

        public int HomeTeamId { get; set; }
        public int AwayTeamId { get; set; }

        [Required, MaxLength(20)]
        public string Status { get; set; } = "Scheduled";

        [MaxLength(100)]
        public string? ExternalRef { get; set; }

        public League? League { get; set; }
        public Team? HomeTeam { get; set; }
        public Team? AwayTeam { get; set; }

        public GameResult? GameResult { get; set; }
        public ICollection<PlayerGameStats> PlayerGameStats { get; set; } = new List<PlayerGameStats>();
        public ICollection<Market> Markets { get; set; } = new List<Market>();
        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
    }

    [Table("GameResult", Schema = "betting")]
    public class GameResult
    {
        [Key]
        public long GameResultId { get; set; }

        public long GameId { get; set; }

        public short HomeScore { get; set; }
        public short AwayScore { get; set; }

        [Required, MaxLength(20)]
        public string FinalStatus { get; set; } = "Final";   // "Final", "Cancelled"

        public bool IsOvertime { get; set; }
        public DateTime UpdatedUtc { get; set; }

        public Game? Game { get; set; }
    }

    [Table("PlayerGameStats", Schema = "betting")]
    public class PlayerGameStats
    {
        [Key]
        public long PlayerGameStatsId { get; set; }

        public long GameId { get; set; }
        public int PlayerId { get; set; }

        public decimal? Minutes { get; set; }
        public short? Points { get; set; }
        public short? Rebounds { get; set; }
        public short? Assists { get; set; }
        public short? Blocks { get; set; }
        public short? Steals { get; set; }
        public short? Turnovers { get; set; }

        public DateTime CreatedUtc { get; set; }
        public DateTime UpdatedUtc { get; set; }

        public Game? Game { get; set; }
        public Player? Player { get; set; }
    }

    // -----------------------------
    // Market metadata
    // -----------------------------

    [Table("MarketType", Schema = "betting")]
    public class MarketType
    {
        [Key]
        public int MarketTypeId { get; set; }

        [Required, MaxLength(40)]
        public string Code { get; set; } = string.Empty;      // "MONEYLINE", "TOTAL_POINTS" etc.

        [Required, MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        public ICollection<Market> Markets { get; set; } = new List<Market>();
        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
    }

    [Table("StatType", Schema = "betting")]
    public class StatType
    {
        [Key]
        public int StatTypeId { get; set; }

        [Required, MaxLength(40)]
        public string Code { get; set; } = string.Empty;      // "POINTS", "REBOUNDS", etc.

        [Required, MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        public ICollection<Market> Markets { get; set; } = new List<Market>();
    }

    [Table("OddsProvider", Schema = "betting")]
    public class OddsProvider
    {
        [Key]
        public long ProviderId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? Code { get; set; }

        [MaxLength(100)]
        public string? ApiIdentifier { get; set; }

        public bool IsActive { get; set; }

        public ICollection<OddsSnapshot> OddsSnapshots { get; set; } = new List<OddsSnapshot>();
        public ICollection<ModelPrediction> ModelPredictions { get; set; } = new List<ModelPrediction>();
        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
        public ICollection<BetTicketLeg> BetTicketLegs { get; set; } = new List<BetTicketLeg>();
    }

    // -----------------------------
    // Markets, outcomes, odds
    // -----------------------------

    [Table("Market", Schema = "betting")]
    public class Market
    {
        [Key]
        public long MarketId { get; set; }

        public long GameId { get; set; }
        public int MarketTypeId { get; set; }
        public int? StatTypeId { get; set; }
        public int? PlayerId { get; set; }

        [Required, MaxLength(20)]
        public string Period { get; set; } = "FULL_GAME";     // FULL_GAME, 1H, 1Q, etc.

        public decimal? LineValue { get; set; }

        public DateTime CreatedUtc { get; set; }
        public bool IsActive { get; set; }

        public Game? Game { get; set; }
        public MarketType? MarketType { get; set; }
        public StatType? StatType { get; set; }
        public Player? Player { get; set; }

        public ICollection<MarketOutcome> Outcomes { get; set; } = new List<MarketOutcome>();
    }

    [Table("MarketOutcome", Schema = "betting")]
    public class MarketOutcome
    {
        [Key]
        public long MarketOutcomeId { get; set; }

        public long MarketId { get; set; }

        [Required, MaxLength(20)]
        public string OutcomeCode { get; set; } = string.Empty;  // "HOME", "AWAY", "OVER", "UNDER"

        [Required, MaxLength(200)]
        public string Description { get; set; } = string.Empty;  // "Home ML", "Over 216.5"

        public byte SortOrder { get; set; }

        public Market? Market { get; set; }
        public ICollection<OddsSnapshot> OddsSnapshots { get; set; } = new List<OddsSnapshot>();
        public ICollection<ModelPrediction> ModelPredictions { get; set; } = new List<ModelPrediction>();
        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
        public ICollection<BetTicketLeg> BetTicketLegs { get; set; } = new List<BetTicketLeg>();
    }

    [Table("OddsSnapshot", Schema = "betting")]
    public class OddsSnapshot
    {
        [Key]
        public long OddsSnapshotId { get; set; }

        public long MarketOutcomeId { get; set; }
        public long ProviderId { get; set; }

        public DateTime SnapshotTimeUtc { get; set; }

        public int AmericanOdds { get; set; }
        public decimal? DecimalOdds { get; set; }
        public decimal? ImpliedProbability { get; set; }

        [MaxLength(50)]
        public string? Source { get; set; }

        public MarketOutcome? MarketOutcome { get; set; }
        public OddsProvider? Provider { get; set; }
    }

    // -----------------------------
    // Models and predictions
    // -----------------------------

    [Table("Model", Schema = "betting")]
    public class Model
    {
        [Key]
        public int ModelId { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(50)]
        public string Version { get; set; } = string.Empty;

        [Required, MaxLength(40)]
        public string ModelTypeCode { get; set; } = string.Empty;  // "MONEYLINE", "PLAYER_POINTS"

        public string? Description { get; set; }

        public bool IsActive { get; set; }

        public ICollection<ModelRun> ModelRuns { get; set; } = new List<ModelRun>();
    }

    [Table("ModelRun", Schema = "betting")]
    public class ModelRun
    {
        [Key]
        public long ModelRunId { get; set; }

        public int ModelId { get; set; }

        [Required, MaxLength(20)]
        public string RunType { get; set; } = "Live";      // Live, Backtest

        public DateTime? FromDateUtc { get; set; }
        public DateTime? ToDateUtc { get; set; }

        public DateTime StartedUtc { get; set; }
        public DateTime? FinishedUtc { get; set; }

        public string? ParametersJson { get; set; }

        public Model? Model { get; set; }
        public ICollection<ModelPrediction> ModelPredictions { get; set; } = new List<ModelPrediction>();
    }

    [Table("ModelPrediction", Schema = "betting")]
    public class ModelPrediction
    {
        [Key]
        public long ModelPredictionId { get; set; }

        public long ModelRunId { get; set; }
        public long MarketOutcomeId { get; set; }
        public long? ProviderId { get; set; }    // null if provider-agnostic

        public decimal WinProbability { get; set; }
        public decimal? FairDecimalOdds { get; set; }
        public int? FairAmericanOdds { get; set; }

        public DateTime CreatedUtc { get; set; }

        public ModelRun? ModelRun { get; set; }
        public MarketOutcome? MarketOutcome { get; set; }
        public OddsProvider? Provider { get; set; }

        public ICollection<BetRecommendation> BetRecommendations { get; set; } = new List<BetRecommendation>();
    }

    // -----------------------------
    // Recommendations and tickets
    // -----------------------------

    [Table("BetRecommendation", Schema = "betting")]
    public class BetRecommendation
    {
        [Key]
        public long BetRecommendationId { get; set; }

        public long ModelPredictionId { get; set; }
        public long MarketOutcomeId { get; set; }
        public long ProviderId { get; set; }

        public long GameId { get; set; }
        public int? PlayerId { get; set; }
        public int MarketTypeId { get; set; }

        public decimal? LineValue { get; set; }

        public int AmericanOdds { get; set; }
        public decimal ImpliedProbability { get; set; }
        public decimal ModelProbability { get; set; }
        public decimal Edge { get; set; }

        [Required, MaxLength(20)]
        public string RiskLevel { get; set; } = string.Empty;   // "Low", "Medium", "High"

        public DateTime CreatedUtc { get; set; }
        public bool IsActive { get; set; }

        public ModelPrediction? ModelPrediction { get; set; }
        public MarketOutcome? MarketOutcome { get; set; }
        public OddsProvider? Provider { get; set; }
        public Game? Game { get; set; }
        public Player? Player { get; set; }
        public MarketType? MarketType { get; set; }

        public ICollection<BetTicketLeg> BetTicketLegs { get; set; } = new List<BetTicketLeg>();
    }

    [Table("BetTicket", Schema = "betting")]
    public class BetTicket
    {
        [Key]
        public long BetTicketId { get; set; }

        public Guid TicketRef { get; set; }
        public DateTime PlacedUtc { get; set; }

        public decimal StakeAmount { get; set; }

        [Required, MaxLength(3)]
        public string CurrencyCode { get; set; } = "USD";

        [MaxLength(50)]
        public string? StrategyTag { get; set; }

        [MaxLength(30)]
        public string? Source { get; set; }                  // "Manual", "Bot"

        [Required, MaxLength(20)]
        public string Status { get; set; } = "Pending";

        [MaxLength(1000)]
        public string? Notes { get; set; }

        public ICollection<BetTicketLeg> Legs { get; set; } = new List<BetTicketLeg>();
    }

    [Table("BetTicketLeg", Schema = "betting")]
    public class BetTicketLeg
    {
        [Key]
        public long BetTicketLegId { get; set; }

        public long BetTicketId { get; set; }
        public long? BetRecommendationId { get; set; }
        public long MarketOutcomeId { get; set; }
        public long ProviderId { get; set; }

        public int AmericanOdds { get; set; }
        public decimal? LineValue { get; set; }

        public decimal? StakeAmount { get; set; }

        [Required, MaxLength(20)]
        public string Status { get; set; } = "Pending";

        public decimal? PayoutAmount { get; set; }

        public BetTicket? BetTicket { get; set; }
        public BetRecommendation? BetRecommendation { get; set; }
        public MarketOutcome? MarketOutcome { get; set; }
        public OddsProvider? Provider { get; set; }
    }

    [Table("TeamRating", Schema = "betting")]
    public class TeamRating
    {
        [Key]
        public int TeamRatingId { get; set; }

        public int TeamId { get; set; }

        [Required, MaxLength(20)]
        public string Season { get; set; } = string.Empty;

        public decimal Rating { get; set; }
        public DateTime LastUpdatedUtc { get; set; }

        public Team? Team { get; set; }
    }
}
