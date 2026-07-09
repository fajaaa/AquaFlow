using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Invoices;

// Hand-written stand-in for IInvoiceService so controller tests can drive
// InvoicesController's ownership pinning without a database. Only the read
// paths carry controller logic, so the write/state-transition members are not supported.
public class FakeInvoiceService : IInvoiceService
{
    private readonly List<InvoiceResponse> _rows;

    public FakeInvoiceService(IEnumerable<InvoiceResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<InvoiceResponse>> GetAllAsync(InvoiceSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.CustomerId is > 0)
        {
            items = items.Where(row => row.CustomerId == search.CustomerId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<InvoiceResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<InvoiceResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<InvoiceResponse> InsertAsync(InvoiceInsertRequest request)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> UpdateAsync(int id, InvoiceUpdateRequest request)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> PatchAsync(int id, InvoicePatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> IssueAsync(int id, int changedById)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> CancelAsync(int id, int changedById)
        => throw new NotSupportedException();

    public Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById)
        => throw new NotSupportedException();

    public Task<List<string>> GetAllowedActionsAsync(int id)
        => throw new NotSupportedException();
}
