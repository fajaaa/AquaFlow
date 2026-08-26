using AquaFlow.Model.Responses;
using AquaFlow.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Feeds the admin desktop dashboard's chart cards. Ungated beyond [Authorize] - the Dashboard tab
// is the admin panel's landing page, visible to every admin regardless of other permissions, so its
// stats stay visible to everyone who can reach that tab (no [RequirePermission], unlike e.g.
// WaterConsumptionAlertsController). Every action shares the same (from, to, cityId) query filter
// triple - see IDashboardService for their defaulting/filtering semantics.
[Authorize]
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
