namespace SmartSportsBetting.Api.Domain.Entities;

public class League
{
    public int LeagueId { get; set; }
    public int SportId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}
