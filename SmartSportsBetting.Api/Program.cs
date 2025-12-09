using System;
using System.Linq;
using System.Reflection;
using System.IO;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using SmartSportsBetting.Infrastructure.Data;

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


// ------------------------------------------------------
// TODAY endpoint
// ------------------------------------------------------
app.MapGet("/api/valuebets/today", async (BettingDbContext db) =>
{
    var todayUtc = DateTime.UtcNow.Date;
    var minEdge = 0.0m;

    var results = await db.DailyValueBets
        .FromSqlRaw(
            "EXEC betting.usp_SelectDailyValueBets @ForDateUtc = {0}, @MinEdge = {1}",
            todayUtc,
            minEdge)
        .ToListAsync();

    return Results.Ok(results);
});


// ------------------------------------------------------
// FLEXIBLE endpoint: GET /api/valuebets?date=YYYY-MM-DD
// ------------------------------------------------------
app.MapGet("/api/valuebets", async (
    BettingDbContext db,
    string? date,
    decimal? minEdge,
    int? take,
    string? marketType) =>
{
    // 1) Parse date (UTC day)
    DateTime dayUtc;
    if (string.IsNullOrWhiteSpace(date))
    {
        dayUtc = DateTime.UtcNow.Date;
    }
    else if (!DateTime.TryParse(date, out dayUtc))
    {
        return Results.BadRequest("Invalid date format. Use yyyy-MM-dd.");
    }

    // 2) Parameters
    var leagueCode = "NBA";
    var mtCode = string.IsNullOrWhiteSpace(marketType) ? null : marketType;
    var min = minEdge ?? 0m;
    var limit = take is > 0 and <= 500 ? take.Value : 50;

    // 3) Call stored procedure
    var rows = await db.DailyValueBets
        .FromSqlRaw(
            @"EXEC betting.usp_SelectValueBets_ByDate 
                    @ForDateUtc = {0},
                    @LeagueCode = {1},
                    @MarketTypeCode = {2},
                    @MinEdge = {3},
                    @IncludePast = {4}",
            dayUtc.Date,
            leagueCode,
            (object?)mtCode ?? DBNull.Value,
            min,
            1   // IncludePast = 1 => whole day, not just upcoming
        )
        .ToListAsync();

    // 4) Apply take() in memory (cheap)
    var result = rows
        .OrderByDescending(r => r.Edge)
        .Take(limit)
        .ToList();

    return Results.Ok(result);
});

app.Run();
