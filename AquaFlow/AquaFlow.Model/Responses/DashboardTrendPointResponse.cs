namespace AquaFlow.Model.Responses;

// One point of a monthly trend chart (revenue/consumption/new-user-count). PeriodStart is always
// the first day of the month, UTC; Flutter formats the label itself (see AGENTS.md "Localization" -
// the backend has no localization infrastructure of its own). Value is decimal so the same shape
// covers both a money total and a unit-count trend without a second DTO.
public class DashboardTrendPointResponse
{
    public DateTime PeriodStart { get; set; }
    public decimal Value { get; set; }
}
