using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

// Backs the admin desktop dashboard's 6 chart cards (revenue trend, invoice status, consumption
// trend, fault report status, new-user trend, water meter request status). Every method takes the
// same (from, to, cityId) filter triple - from/to default to a rolling last-12-months window when
// null (see DashboardService.ResolveRange), cityId filters through Settlement -> Municipality -> City
// when supplied and is ignored (no filter) when null.
public interface IDashboardService
{
    Task<List<DashboardTrendPointResponse>> GetRevenueTrendAsync(DateTime? from, DateTime? to, int? cityId);
    Task<List<DashboardStatusBreakdownResponse>> GetInvoiceStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId);
    Task<List<DashboardTrendPointResponse>> GetConsumptionTrendAsync(DateTime? from, DateTime? to, int? cityId);
    Task<List<DashboardStatusBreakdownResponse>> GetFaultReportStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId);
    Task<List<DashboardTrendPointResponse>> GetUserGrowthTrendAsync(DateTime? from, DateTime? to, int? cityId);
    Task<List<DashboardStatusBreakdownResponse>> GetWaterMeterRequestStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId);
}
