using AquaFlow.Model.Responses;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Feeds the admin desktop dashboard's chart cards with company-wide aggregates (revenue, invoice
// status, consumption, fault reports, user growth, water meter requests). That is business data no
// customer or collector should see, and hiding the tab in the desktop app is not a security control,
// so the whole controller is gated at class level with Dashboard.Read (seeded onto Admin only) - same
// "no self-service caller at all" reasoning as WaterConsumptionAlertsController. Every action shares
// the same (from, to, cityId) query filter triple - see IDashboardService for their
// defaulting/filtering semantics.
[Authorize]
[RequirePermission("Dashboard.Read")]
[ApiController]
[Route("[controller]")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("revenue-trend")]
    public async Task<ActionResult<List<DashboardTrendPointResponse>>> GetRevenueTrend(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetRevenueTrendAsync(from, to, cityId));
    }

    [HttpGet("invoice-status")]
    public async Task<ActionResult<List<DashboardStatusBreakdownResponse>>> GetInvoiceStatusBreakdown(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetInvoiceStatusBreakdownAsync(from, to, cityId));
    }

    [HttpGet("consumption-trend")]
    public async Task<ActionResult<List<DashboardTrendPointResponse>>> GetConsumptionTrend(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetConsumptionTrendAsync(from, to, cityId));
    }

    [HttpGet("fault-report-status")]
    public async Task<ActionResult<List<DashboardStatusBreakdownResponse>>> GetFaultReportStatusBreakdown(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetFaultReportStatusBreakdownAsync(from, to, cityId));
    }

    [HttpGet("user-growth-trend")]
    public async Task<ActionResult<List<DashboardTrendPointResponse>>> GetUserGrowthTrend(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetUserGrowthTrendAsync(from, to, cityId));
    }

    [HttpGet("water-meter-request-status")]
    public async Task<ActionResult<List<DashboardStatusBreakdownResponse>>> GetWaterMeterRequestStatusBreakdown(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        return Ok(await _dashboardService.GetWaterMeterRequestStatusBreakdownAsync(from, to, cityId));
    }
}
