using Microsoft.EntityFrameworkCore;
using SmartSportsBetting.Api.Domain.Entities;

namespace SmartSportsBetting.Api.Data;

public class BettingDbContext : DbContext
{
    public BettingDbContext(DbContextOptions<BettingDbContext> options) : base(options)
    {
    }

    public DbSet<Game> Games => Set<Game>();
    public DbSet<GameOdds> GameOdds => Set<GameOdds>();
    public DbSet<BetRecommendation> BetRecommendations => Set<BetRecommendation>();

    // Added to support value bets query
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<League> Leagues => Set<League>();
    public DbSet<OddsProvider> OddsProviders => Set<OddsProvider>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Game>(entity =>
        {
            entity.ToTable("Game", "betting");
            entity.HasKey(e => e.GameId);
        });

        modelBuilder.Entity<GameOdds>(entity =>
        {
            entity.ToTable("GameOdds", "betting");
            entity.HasKey(e => e.GameOddsId);
        });

        modelBuilder.Entity<BetRecommendation>(entity =>
        {
            entity.ToTable("BetRecommendation", "betting");
            entity.HasKey(e => e.BetRecommendationId);
        });

        modelBuilder.Entity<Team>(entity =>
        {
            entity.ToTable("Team", "betting");
            entity.HasKey(e => e.TeamId);
        });

        modelBuilder.Entity<League>(entity =>
        {
            entity.ToTable("League", "betting");
            entity.HasKey(e => e.LeagueId);
        });

        modelBuilder.Entity<OddsProvider>(entity =>
        {
            entity.ToTable("OddsProvider", "betting");
            entity.HasKey(e => e.OddsProviderId);
        });
    }
}
