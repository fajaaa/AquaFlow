namespace AquaFlow.Services.Pdf;

public interface IInvoicePdfService
{
    // Loads the invoice (with Customer/WaterMeter/InvoiceItems) and the single CompanySettings row
    // itself - the caller only needs to have already verified ownership/permission. Throws
    // KeyNotFoundException when the invoice does not exist.
    Task<byte[]> GenerateInvoicePdfAsync(int invoiceId);
}
