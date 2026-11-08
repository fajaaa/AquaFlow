using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;

namespace AquaFlow.Services;

// One CRUD contract for every codebook; TEntity only tells the DI container (and the
// LookupController<TEntity> base) which table a given instance works on.
public interface ILookupService<TEntity>
    : IBaseCRUDService<LookupResponse, LookupSearchObject, LookupInsertRequest, LookupUpdateRequest, LookupPatchRequest>
    where TEntity : LookupEntityBase
{
}
