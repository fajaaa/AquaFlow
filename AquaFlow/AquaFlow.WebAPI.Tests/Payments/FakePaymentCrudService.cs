using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Payments;

// Hand-written stand-in for IBaseCRUDService<...> so controller tests can drive
// PaymentsController's ownership pinning without a database. Only the read
// paths carry controller logic, so the write members are not supported.
public class FakePaymentCrudService
    : IBaseCRUDService<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest>
{
    private readonly List<PaymentResponse> _rows;

    public FakePaymentCrudService(IEnumerable<PaymentResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<PaymentResponse>> GetAllAsync(PaymentSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.CustomerId is > 0)
        {
            items = items.Where(row => row.CustomerId == search.CustomerId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<PaymentResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<PaymentResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }

    public Task<PaymentResponse> InsertAsync(PaymentInsertRequest request)
        => throw new NotSupportedException();

    public Task<PaymentResponse> UpdateAsync(int id, PaymentUpdateRequest request)
        => throw new NotSupportedException();

    public Task<PaymentResponse> PatchAsync(int id, PaymentPatchRequest request)
        => throw new NotSupportedException();

    public Task DeleteAsync(int id)
        => throw new NotSupportedException();
}
