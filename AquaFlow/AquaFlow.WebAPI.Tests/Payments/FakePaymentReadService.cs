using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.Payments;

// Hand-written stand-in for IBaseReadService<...> so controller tests can drive
// PaymentsController's ownership pinning without a database. /Payments is read-only
// (see PaymentsController), so there is no write counterpart to fake.
public class FakePaymentReadService : IBaseReadService<PaymentResponse, PaymentSearchObject>
{
    private readonly List<PaymentResponse> _rows;

    public FakePaymentReadService(IEnumerable<PaymentResponse> rows)
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
}
