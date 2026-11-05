using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Pdf;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Admin-only PDF reports (consumption per settlement, billing/collection). Gated at class level with
// Dashboard.Read (seeded onto Admin only), same reasoning as DashboardController.
[Authorize]
[RequirePermission("Dashboard.Read")]
[ApiController]
[Route("[controller]")]
public class ReportsController : ControllerBase
{
    private const int MaxRangeDays = 366;

    private readonly IReportPdfService _reportPdfService;

    public ReportsController(IReportPdfService reportPdfService)
    {
        _reportPdfService = reportPdfService;
    }

    [HttpGet("consumption/pdf")]
    public async Task<IActionResult> GetConsumptionPdf(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        var (f, t) = ValidateRange(from, to);
        var bytes = await _reportPdfService.GenerateConsumptionReportAsync(f, t, cityId);
        return File(bytes, "application/pdf", $"izvjestaj-potrosnja-{f:yyyy-MM-dd}_{t:yyyy-MM-dd}.pdf");
    }

    [HttpGet("billing/pdf")]
    public async Task<IActionResult> GetBillingPdf(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? cityId)
    {
        var (f, t) = ValidateRange(from, to);
        var bytes = await _reportPdfService.GenerateBillingReportAsync(f, t, cityId);
        return File(bytes, "application/pdf", $"izvjestaj-naplata-{f:yyyy-MM-dd}_{t:yyyy-MM-dd}.pdf");
    }

    private static (DateTime From, DateTime To) ValidateRange(DateTime? from, DateTime? to)
    {
        if (!from.HasValue || !to.HasValue)
        {
            throw new ClientException("Parametri 'from' i 'to' su obavezni.");
        }

        var f = from.Value.Date;
        var t = to.Value.Date;
        if (f > t)
        {
            throw new ClientException("Datum 'from' ne smije biti poslije datuma 'to'.");
        }

        if ((t - f).TotalDays > MaxRangeDays)
        {
            throw new ClientException($"Period ne smije biti duži od {MaxRangeDays} dana.");
        }

        return (f, t);
    }
}
