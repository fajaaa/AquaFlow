using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IBillingCycleService
    : IBaseCRUDService<BillingCycleResponse, BillingCycleSearchObject, BillingCycleInsertRequest, BillingCycleUpdateRequest, BillingCyclePatchRequest>
{
}
