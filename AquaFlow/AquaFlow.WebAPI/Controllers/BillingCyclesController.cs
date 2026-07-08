using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Controllers;

// Read-only (see BillingCycleService). Any authenticated caller can read - a collector needs
// GET /BillingCycles?Status=Open to show the current period on the reading-entry screen, the same
// way any authenticated caller can read Tariffs.
public class BillingCyclesController : BaseReadController<BillingCycleResponse, BillingCycleSearchObject, IBillingCycleService>
{
    public BillingCyclesController(IBillingCycleService service) : base(service)
    {
    }
}
