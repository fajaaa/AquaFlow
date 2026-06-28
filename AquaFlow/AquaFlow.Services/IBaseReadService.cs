using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IBaseReadService<TResponse, TSearch>
    where TSearch : BaseSearchObject
{
    Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null);
    Task<TResponse> GetByIdAsync(int id);
}
