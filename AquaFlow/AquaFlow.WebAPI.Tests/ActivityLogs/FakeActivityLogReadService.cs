using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.ActivityLogs;

// Hand-written stand-in for IBaseReadService<...> so ActivityLogsController tests can
// drive its ownership/permission logic without a database.
public class FakeActivityLogReadService : IBaseReadService<ActivityLogResponse, ActivityLogSearchObject>
{
    private readonly List<ActivityLogResponse> _rows;

    public FakeActivityLogReadService(IEnumerable<ActivityLogResponse> rows)
    {
        _rows = rows.ToList();
    }

    public Task<PageResult<ActivityLogResponse>> GetAllAsync(ActivityLogSearchObject? search = null)
    {
        var items = _rows.AsEnumerable();
        if (search?.UserId is > 0)
        {
            items = items.Where(row => row.UserId == search.UserId);
        }

        var list = items.ToList();
        return Task.FromResult(new PageResult<ActivityLogResponse>
        {
            Items = list,
            TotalCount = list.Count
        });
    }

    public Task<ActivityLogResponse> GetByIdAsync(int id)
    {
        var row = _rows.SingleOrDefault(row => row.Id == id);
        if (row is null)
        {
            throw new KeyNotFoundException();
        }

        return Task.FromResult(row);
    }
}
