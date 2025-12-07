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
    }
}
