namespace SmartSportsBetting.Api.Domain.Entities;

public class Game
{
    public long GameId { get; set; }
    public int LeagueId { get; set; }
    public int Season { get; set; }
    public DateTime GameDateTime { get; set; }
    public int HomeTeamId { get; set; }
    public int AwayTeamId { get; set; }
    public string Status { get; set; } = "Scheduled";
    public int? HomeScore { get; set; }
    public int? AwayScore { get; set; }
    public string? ExternalRef { get; set; }
}
