namespace SmartSportsBetting.Infrastructure.Models
{
    public class ValueBetDto
    {
        public long BetRecommendationId { get; set; }
        public string League { get; set; } = string.Empty;
        public string HomeTeam { get; set; } = string.Empty;
        public string AwayTeam { get; set; } = string.Empty;
        public DateTime GameTime { get; set; }
        public string Provider { get; set; } = string.Empty;
        public string BetType { get; set; } = string.Empty;
        public decimal? LineValue { get; set; }
        public int BookOdds { get; set; }
        public decimal ModelProbability { get; set; }
        public decimal ImpliedProbability { get; set; }
        public decimal Edge { get; set; }
        public string RiskLevel { get; set; } = string.Empty;
    }
}
