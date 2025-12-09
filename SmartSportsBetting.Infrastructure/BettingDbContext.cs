using Microsoft.EntityFrameworkCore;
using SmartSportsBetting.Domain.Entities;
using SmartSportsBetting.Infrastructure.Models;

namespace SmartSportsBetting.Infrastructure.Data
{
    public class BettingDbContext : DbContext
    {
        public BettingDbContext(DbContextOptions<BettingDbContext> options)
            : base(options)
        {
        }

        public DbSet<Sport> Sports => Set<Sport>();
        public DbSet<League> Leagues => Set<League>();
        public DbSet<Team> Teams => Set<Team>();
        public DbSet<Player> Players => Set<Player>();

        public DbSet<TeamRating> TeamRatings => Set<TeamRating>();

        public DbSet<Game> Games => Set<Game>();
        public DbSet<GameResult> GameResults => Set<GameResult>();
        public DbSet<PlayerGameStats> PlayerGameStats => Set<PlayerGameStats>();

        public DbSet<MarketType> MarketTypes => Set<MarketType>();
        public DbSet<StatType> StatTypes => Set<StatType>();
        public DbSet<OddsProvider> OddsProviders => Set<OddsProvider>();

        public DbSet<Market> Markets => Set<Market>();
        public DbSet<MarketOutcome> MarketOutcomes => Set<MarketOutcome>();
        public DbSet<OddsSnapshot> OddsSnapshots => Set<OddsSnapshot>();

        public DbSet<Model> Models => Set<Model>();
        public DbSet<ModelRun> ModelRuns => Set<ModelRun>();
        public DbSet<ModelPrediction> ModelPredictions => Set<ModelPrediction>();

        public DbSet<BetRecommendation> BetRecommendations => Set<BetRecommendation>();
        public DbSet<BetTicket> BetTickets => Set<BetTicket>();
        public DbSet<BetTicketLeg> BetTicketLegs => Set<BetTicketLeg>();
        public DbSet<ValueBetDto> DailyValueBets { get; set; } = default!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // If you want, you can set default schema once instead of [Table(..., Schema="betting")]
            // modelBuilder.HasDefaultSchema("betting");

            // Example: configure the Game home/away relationships explicitly
            modelBuilder.Entity<Game>()
                .HasOne(g => g.HomeTeam)
                .WithMany(t => t.HomeGames)
                .HasForeignKey(g => g.HomeTeamId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Game>()
                .HasOne(g => g.AwayTeam)
                .WithMany(t => t.AwayGames)
                .HasForeignKey(g => g.AwayTeamId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<BetRecommendation>(e =>
            {
                e.Property(p => p.LineValue).HasPrecision(8, 3);
                e.Property(p => p.ImpliedProbability).HasPrecision(6, 5);
                e.Property(p => p.ModelProbability).HasPrecision(6, 5);
                e.Property(p => p.Edge).HasPrecision(7, 6);
            });

            modelBuilder.Entity<BetTicket>(e =>
            {
                e.Property(p => p.StakeAmount).HasPrecision(12, 2);
            });

            modelBuilder.Entity<BetTicketLeg>(e =>
            {
                e.Property(p => p.LineValue).HasPrecision(8, 3);
                e.Property(p => p.StakeAmount).HasPrecision(12, 2);
                e.Property(p => p.PayoutAmount).HasPrecision(12, 2);
            });

            modelBuilder.Entity<Market>(e =>
            {
                e.Property(p => p.LineValue).HasPrecision(8, 3);
            });

            modelBuilder.Entity<ModelPrediction>(e =>
            {
                e.Property(p => p.FairDecimalOdds).HasPrecision(10, 4);
                e.Property(p => p.WinProbability).HasPrecision(6, 5);
            });

            modelBuilder.Entity<OddsSnapshot>(e =>
            {
                e.Property(p => p.DecimalOdds).HasPrecision(10, 4);
                e.Property(p => p.ImpliedProbability).HasPrecision(6, 5);
            });

            modelBuilder.Entity<PlayerGameStats>(e =>
            {
                e.Property(p => p.Minutes).HasPrecision(5, 2);
            });

            modelBuilder.Entity<ValueBetDto>()
                            .HasNoKey()
                            .ToView(null);   // result of stored procedure, not a mapped view

        }


    }
}
