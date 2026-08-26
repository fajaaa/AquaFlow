using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class DashboardService : IDashboardService
{
    private readonly AquaFlowDbContext _context;

    public DashboardService(AquaFlowDbContext context)
    {
        _context = context;
    }

    public async Task<List<DashboardTrendPointResponse>> GetRevenueTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.Payments.Where(p =>
            p.Status == PaymentStatus.Completed &&
            p.PaidAt != null && p.PaidAt >= fromMonth && p.PaidAt < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(p => p.Customer!.Settlement!.Municipality!.CityId == cityId);
        }

        var grouped = await query
            .GroupBy(p => new { p.PaidAt!.Value.Year, p.PaidAt!.Value.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Total = g.Sum(p => p.Amount) })
            .ToListAsync();

        return BuildMonthlyTrend(
            grouped.ToDictionary(g => (g.Year, g.Month), g => g.Total),
            fromMonth,
            toExclusiveMonth);
    }

    public async Task<List<DashboardStatusBreakdownResponse>> GetInvoiceStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.Invoices.Where(i => i.CreatedAt >= fromMonth && i.CreatedAt < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(i => i.Customer!.Settlement!.Municipality!.CityId == cityId);
        }

        return await query
            .GroupBy(i => i.Status)
            .Select(g => new DashboardStatusBreakdownResponse
            {
                Status = g.Key,
                Count = g.Count(),
                TotalAmount = g.Sum(i => i.TotalAmount),
            })
            .ToListAsync();
    }

    public async Task<List<DashboardTrendPointResponse>> GetConsumptionTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.MeterReadings.Where(r =>
            r.VoidedAt == null && r.ReadingDate >= fromMonth && r.ReadingDate < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(r => r.WaterMeter!.Settlement!.Municipality!.CityId == cityId);
        }

        var grouped = await query
            .GroupBy(r => new { r.ReadingDate.Year, r.ReadingDate.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Total = g.Sum(r => r.ConsumptionM3) })
            .ToListAsync();

        return BuildMonthlyTrend(
            grouped.ToDictionary(g => (g.Year, g.Month), g => g.Total),
            fromMonth,
            toExclusiveMonth);
    }

    public async Task<List<DashboardStatusBreakdownResponse>> GetFaultReportStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.FaultReports.Where(f => f.CreatedAt >= fromMonth && f.CreatedAt < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(f => f.Settlement!.Municipality!.CityId == cityId);
        }

        return await query
            .GroupBy(f => f.Status)
            .Select(g => new DashboardStatusBreakdownResponse { Status = g.Key, Count = g.Count() })
            .ToListAsync();
    }

    public async Task<List<DashboardTrendPointResponse>> GetUserGrowthTrendAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.Users.Where(u => u.CreatedAt >= fromMonth && u.CreatedAt < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(u => u.CustomerProfile!.Settlement!.Municipality!.CityId == cityId);
        }

        var grouped = await query
            .GroupBy(u => new { u.CreatedAt.Year, u.CreatedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
            .ToListAsync();

        return BuildMonthlyTrend(
            grouped.ToDictionary(g => (g.Year, g.Month), g => (decimal)g.Count),
            fromMonth,
            toExclusiveMonth);
    }

    public async Task<List<DashboardStatusBreakdownResponse>> GetWaterMeterRequestStatusBreakdownAsync(DateTime? from, DateTime? to, int? cityId)
    {
        var (fromMonth, toExclusiveMonth) = ResolveMonthRange(from, to);

        var query = _context.WaterMeterRequests.Where(r => r.CreatedAt >= fromMonth && r.CreatedAt < toExclusiveMonth);
        if (cityId.HasValue)
        {
            query = query.Where(r => r.Settlement!.Municipality!.CityId == cityId);
        }

        return await query
            .GroupBy(r => r.Status)
            .Select(g => new DashboardStatusBreakdownResponse { Status = g.Key, Count = g.Count() })
            .ToListAsync();
    }

    // Both bounds resolve to whole calendar months (UTC) so every chart's default window is
    // identical - a rolling last-12-months, ending with the month containing `to` (or today when
    // `to` is null) - and BuildMonthlyTrend can zero-fill a gap-free monthly sequence from them.
    private static (DateTime FromMonth, DateTime ToExclusiveMonth) ResolveMonthRange(DateTime? from, DateTime? to)
    {
        var referenceEnd = to ?? DateTime.UtcNow;
        var toExclusiveMonth = new DateTime(referenceEnd.Year, referenceEnd.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(1);

        var referenceStart = from ?? toExclusiveMonth.AddMonths(-12);
        var fromMonth = new DateTime(referenceStart.Year, referenceStart.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        return (fromMonth, toExclusiveMonth);
    }

    // Zero-fills every month in [fromMonth, toExclusiveMonth) so a line/bar chart never silently
    // skips a month with no rows - the alternative (only emitting months with data) would draw a
    // misleading line straight across a real gap.
    private static List<DashboardTrendPointResponse> BuildMonthlyTrend(
        IReadOnlyDictionary<(int Year, int Month), decimal> values,
        DateTime fromMonth,
        DateTime toExclusiveMonth)
    {
        var points = new List<DashboardTrendPointResponse>();
        for (var month = fromMonth; month < toExclusiveMonth; month = month.AddMonths(1))
        {
            values.TryGetValue((month.Year, month.Month), out var value);
            points.Add(new DashboardTrendPointResponse { PeriodStart = month, Value = value });
        }
        return points;
    }
}
