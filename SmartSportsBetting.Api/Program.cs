using System;
using System.Linq;
using System.Reflection;
using System.IO;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using SmartSportsBetting.Api.Data;
using SmartSportsBetting.Api.Models;
using SmartSportsBetting.Api.Domain.Entities;

var builder = WebApplication.CreateBuilder(args);

// Configure DbContext: prefer configured SQL Server connection, fall back to InMemory when no connection string is provided
var conn = builder.Configuration.GetConnectionString("BettingDb");
if (!string.IsNullOrWhiteSpace(conn))
{
    builder.Services.AddDbContext<BettingDbContext>(options =>
        options.UseSqlServer(conn));
}
else
{
    builder.Services.AddDbContext<BettingDbContext>(options =>
        options.UseInMemoryDatabase("dev"));
}

// Add minimal API + Swagger/OpenAPI support
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SmartSportsBetting API",
        Version = "v1",
        Description = "API for value bet recommendations"
    });

    // Include XML comments if present
    try
    {
        var xmlFile = Path.ChangeExtension(Assembly.GetExecutingAssembly().Location, ".xml");
        if (File.Exists(xmlFile))
        {
            options.IncludeXmlComments(xmlFile);
        }
    }
    catch
    {
        // ignore if unable to locate xml file
    }
});

var app = builder.Build();

// Always enable Swagger (useful for local testing)
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartSportsBetting API v1");
});

if (app.Environment.IsDevelopment())
{
    // additional development-only middleware could go here
}

app.MapGet("/", () => "SmartSportsBetting API is running");

// Today's value bets
app.MapGet("/api/valuebets/today", async (BettingDbContext db) =>
{
    var todayUtc = DateTime.UtcNow.Date;
    var tomorrowUtc = todayUtc.AddDays(1);

    var query =
        from br in db.BetRecommendations
        join g in db.Games on br.GameId equals g.GameId
        join ht in db.Teams on g.HomeTeamId equals ht.TeamId
        join at in db.Teams on g.AwayTeamId equals at.TeamId
        join l in db.Leagues on g.LeagueId equals l.LeagueId
        join p in db.OddsProviders on br.OddsProviderId equals p.OddsProviderId
        where br.CreatedUtc >= todayUtc && br.CreatedUtc < tomorrowUtc
        orderby br.Edge descending
        select new ValueBetDto
        {
            BetRecommendationId = br.BetRecommendationId,
            League = l.Code,
            HomeTeam = ht.Name,
            AwayTeam = at.Name,
            GameTime = g.GameDateTime,
            Provider = p.Code,
            BetType = br.BetType,
            LineValue = br.LineValue,
            BookOdds = br.BookOdds,
            ModelProbability = br.ModelProbability,
            ImpliedProbability = br.ImpliedProbability,
            Edge = br.Edge,
            RiskLevel = br.RiskLevel
        };

    var results = await query.Take(50).ToListAsync();
    return Results.Ok(results);
});

app.Run();
