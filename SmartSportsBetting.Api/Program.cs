using Microsoft.EntityFrameworkCore;
using SmartSportsBetting.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Add DbContext
builder.Services.AddDbContext<BettingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("BettingDb")));

var app = builder.Build();

app.MapGet("/", () => "SmartSportsBetting API is running");

// Simple endpoint for today's value bets (skeleton)
app.MapGet("/api/valuebets/today", async (BettingDbContext db) =>
{
    var todayUtc = DateTime.UtcNow.Date;
    var tomorrowUtc = todayUtc.AddDays(1);

    var bets = await db.BetRecommendations
        .Where(b => b.CreatedUtc >= todayUtc && b.CreatedUtc < tomorrowUtc)
        .OrderByDescending(b => b.Edge)
        .Take(50)
        .ToListAsync();

    return Results.Ok(bets);
});

app.Run();

