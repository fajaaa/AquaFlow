using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.WebAPI.Filters;
using Microsoft.AspNetCore.Mvc;

namespace AquaFlow.WebAPI.Controllers;

// Shared base for every codebook endpoint: GET is open to any authenticated user (inherited
// [Authorize]); writes require Codebooks.Manage (Admin). Business rules live in LookupService.
public abstract class LookupController<TEntity>
    : BaseCRUDController<LookupResponse, LookupSearchObject, LookupInsertRequest, LookupUpdateRequest, LookupPatchRequest, ILookupService<TEntity>>
    where TEntity : LookupEntityBase
{
    protected LookupController(ILookupService<TEntity> service) : base(service)
    {
    }

    [RequirePermission("Codebooks.Manage")]
    public override Task<ActionResult<LookupResponse>> Create([FromBody] LookupInsertRequest request)
        => base.Create(request);

    [RequirePermission("Codebooks.Manage")]
    public override Task<ActionResult<LookupResponse>> Update(int id, [FromBody] LookupUpdateRequest request)
        => base.Update(id, request);

    [RequirePermission("Codebooks.Manage")]
    public override Task<ActionResult<LookupResponse>> Patch(int id, [FromBody] LookupPatchRequest request)
        => base.Patch(id, request);

    [RequirePermission("Codebooks.Manage")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}

public class InvoiceStatusesController(ILookupService<InvoiceStatusLookup> service)
    : LookupController<InvoiceStatusLookup>(service);

public class PaymentStatusesController(ILookupService<PaymentStatusLookup> service)
    : LookupController<PaymentStatusLookup>(service);

public class PaymentMethodsController(ILookupService<PaymentMethodLookup> service)
    : LookupController<PaymentMethodLookup>(service);

public class FaultReportStatusesController(ILookupService<FaultReportStatusLookup> service)
    : LookupController<FaultReportStatusLookup>(service);

public class WaterMeterRequestStatusesController(ILookupService<WaterMeterRequestStatusLookup> service)
    : LookupController<WaterMeterRequestStatusLookup>(service);

public class WaterMeterStatusesController(ILookupService<WaterMeterStatusLookup> service)
    : LookupController<WaterMeterStatusLookup>(service);

public class SupportTicketStatusesController(ILookupService<SupportTicketStatusLookup> service)
    : LookupController<SupportTicketStatusLookup>(service);

public class NotificationTypesController(ILookupService<NotificationTypeLookup> service)
    : LookupController<NotificationTypeLookup>(service);

public class NotificationAudiencesController(ILookupService<NotificationAudienceLookup> service)
    : LookupController<NotificationAudienceLookup>(service);

public class ConsumptionAlertTypesController(ILookupService<ConsumptionAlertTypeLookup> service)
    : LookupController<ConsumptionAlertTypeLookup>(service);
