namespace SmartSportsBetting.Api.Domain.Entities;

public class Team
{
    public int TeamId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}
