using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// GetAll/GetById stay ungated (any authenticated caller can read) - a collector needs
// GET /BillingCycles?Status=Open to show the current period on the reading-entry screen, the same
// way any authenticated caller can read Tariffs. Create/Update/Patch/Delete require
// BillingCycles.Manage (Admin only) - see BillingCycleService for the single-Open-cycle invariant.
public class BillingCyclesController
    : BaseCRUDController<BillingCycleResponse, BillingCycleSearchObject, BillingCycleInsertRequest, BillingCycleUpdateRequest, BillingCyclePatchRequest, IBillingCycleService>
{
    private const string ManagePermission = "BillingCycles.Manage";

    public BillingCyclesController(IBillingCycleService service) : base(service)
    {
    }

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<BillingCycleResponse>> Create([FromBody] BillingCycleInsertRequest request)
        => base.Create(request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<BillingCycleResponse>> Update(int id, [FromBody] BillingCycleUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<ActionResult<BillingCycleResponse>> Patch(int id, [FromBody] BillingCyclePatchRequest request)
        => base.Patch(id, request);

    [RequirePermission(ManagePermission)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
