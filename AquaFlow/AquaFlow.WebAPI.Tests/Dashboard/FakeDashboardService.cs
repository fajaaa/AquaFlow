using AquaFlow.Model.Responses;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Dashboard;

// Records the (from, to, cityId) triple each method was called with, so tests can assert the
// controller passes its query parameters straight through without transforming them.
public class FakeDashboardService : IDashboardService
{
    public (DateTime? From, DateTime? To, int? CityId)? LastCall { get; private set; }

    public List<DashboardTrendPointResponse> TrendResult { get; set; } = new();
    public List<DashboardStatusBreakdownResponse> BreakdownResult { get; set; } = new();

    public Task<List<DashboardTrendPointResponse>> GetRevenueTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(TrendResult);
    }

    public Task<List<DashboardStatusBreakdownResponse>> GetInvoiceStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(BreakdownResult);
    }

    public Task<List<DashboardTrendPointResponse>> GetConsumptionTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(TrendResult);
    }

    public Task<List<DashboardStatusBreakdownResponse>> GetFaultReportStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(BreakdownResult);
    }

    public Task<List<DashboardTrendPointResponse>> GetUserGrowthTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(TrendResult);
    }

    public Task<List<DashboardStatusBreakdownResponse>> GetWaterMeterRequestStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        LastCall = (from, to, cityId);
        return Task.FromResult(BreakdownResult);
    }
}
