using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>
    : IBaseReadService<TResponse, TSearch>
    where TSearch : BaseSearchObject
{
    Task<TResponse> InsertAsync(TInsertRequest request);
    Task<TResponse> UpdateAsync(int id, TUpdateRequest request);
    Task<TResponse> PatchAsync(int id, TPatchRequest request);
    Task DeleteAsync(int id);
}
