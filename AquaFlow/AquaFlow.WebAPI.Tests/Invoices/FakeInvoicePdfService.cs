using AquaFlow.Services.Pdf;

namespace AquaFlow.WebAPI.Tests.Invoices;

// Hand-written stand-in for IInvoicePdfService so InvoicesControllerTests can drive GetPdf without
// QuestPDF/a database - the actual PDF rendering (and the CompanySettings.LogoUrl edge case) is
// covered separately by AquaFlow.Services.Tests/Pdf/InvoicePdfServiceTests.
public class FakeInvoicePdfService : IInvoicePdfService
{
    private readonly HashSet<int> _existingInvoiceIds;

    public FakeInvoicePdfService(IEnumerable<int> existingInvoiceIds)
    {
        _existingInvoiceIds = existingInvoiceIds.ToHashSet();
    }

    public int? LastRequestedInvoiceId { get; private set; }

    public Task<byte[]> GenerateInvoicePdfAsync(int invoiceId)
    {
        LastRequestedInvoiceId = invoiceId;
        if (!_existingInvoiceIds.Contains(invoiceId))
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(new byte[] { 0x25, 0x50, 0x44, 0x46 });
    }
}
