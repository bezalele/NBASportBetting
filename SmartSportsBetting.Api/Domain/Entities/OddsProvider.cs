namespace SmartSportsBetting.Api.Domain.Entities;

public class OddsProvider
{
    public int OddsProviderId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ApiSource { get; set; }
}
