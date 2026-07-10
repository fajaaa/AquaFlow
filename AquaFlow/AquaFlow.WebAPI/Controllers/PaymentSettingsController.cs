using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

using PaymentSettingsCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.PaymentSettingsResponse, AquaFlow.Model.SearchObjects.PaymentSettingsSearchObject, AquaFlow.Model.Requests.PaymentSettingsInsertRequest, AquaFlow.Model.Requests.PaymentSettingsUpdateRequest, AquaFlow.Model.Requests.PaymentSettingsPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// /PaymentSettings is the raw admin table, same precedent as NotificationsController: every
// action - including GetAll/GetById - requires PaymentSettings.Manage. It carries payment
// gateway configuration (PayPal client id, card provider), so it is more sensitive than
// CompanySettings and has no self-service equivalent at all.
public class PaymentSettingsController : BaseCRUDController<PaymentSettingsResponse, PaymentSettingsSearchObject, PaymentSettingsInsertRequest, PaymentSettingsUpdateRequest, PaymentSettingsPatchRequest, PaymentSettingsCrudService>
{
    public PaymentSettingsController(PaymentSettingsCrudService service) : base(service)
    {
    }

    [RequirePermission("PaymentSettings.Manage")]
    public override Task<ActionResult<PageResult<PaymentSettingsResponse>>> GetAll([FromQuery] PaymentSettingsSearchObject? search)
        => base.GetAll(search);

    [RequirePermission("PaymentSettings.Manage")]
    public override Task<ActionResult<PaymentSettingsResponse>> GetById(int id)
        => base.GetById(id);

    // UpdatedById records who last touched the payment configuration. It must never come
    // from the request body - any Manage holder could otherwise name someone else - so it
    // is always forced to the caller's own id from the JWT, same pattern as
    // NotificationsController.Create forcing CreatedById.
    [RequirePermission("PaymentSettings.Manage")]
    public override Task<ActionResult<PaymentSettingsResponse>> Create([FromBody] PaymentSettingsInsertRequest request)
    {
        request.UpdatedById = GetCurrentUserId();
        return base.Create(request);
    }

    [RequirePermission("PaymentSettings.Manage")]
    public override Task<ActionResult<PaymentSettingsResponse>> Update(int id, [FromBody] PaymentSettingsUpdateRequest request)
    {
        request.UpdatedById = GetCurrentUserId();
        return base.Update(id, request);
    }

    [RequirePermission("PaymentSettings.Manage")]
    public override Task<ActionResult<PaymentSettingsResponse>> Patch(int id, [FromBody] PaymentSettingsPatchRequest request)
    {
        request.UpdatedById = GetCurrentUserId();
        return base.Patch(id, request);
    }

    [RequirePermission("PaymentSettings.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    private int GetCurrentUserId()
    {
        var raw = User.FindFirst(ClaimNames.Id)?.Value;
        if (!int.TryParse(raw, out var id))
        {
            throw new ClientException("Could not determine the signed-in user.");
        }
        return id;
    }
}
