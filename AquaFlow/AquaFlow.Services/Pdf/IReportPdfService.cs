namespace AquaFlow.Services.Pdf;

// Admin-facing PDF reports. Both take an inclusive [from, to] date range (to = end of that day)
// and an optional city filter.
public interface IReportPdfService
{
    Task<byte[]> GenerateConsumptionReportAsync(DateTime from, DateTime to, int? cityId);
    Task<byte[]> GenerateBillingReportAsync(DateTime from, DateTime to, int? cityId);
}
