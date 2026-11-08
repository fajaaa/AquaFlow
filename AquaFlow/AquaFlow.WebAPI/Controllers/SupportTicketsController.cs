using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Read side follows ActivityLogsController (BaseReadController over ISupportTicketService, which is
// itself an IBaseReadService), with custom write routes bolted on. Ownership mirrors
// FaultReportsController/WaterMeterRequestsController: a SupportTickets.Manage holder (staff) passes
// through unfiltered; everyone else is a customer who only ever sees/writes their own tickets,
// keyed on the ticket's CustomerId == the caller's CustomerProfile.Id (resolved from the JWT id,
// same lookup WaterMetersController uses). "Not yours" surfaces as 404 (not Forbid) so the response
// never confirms another customer's ticket id exists.
public class SupportTicketsController : BaseReadController<SupportTicketResponse, SupportTicketSearchObject, ISupportTicketService>
{
    private const string ManagePermission = "SupportTickets.Manage";
    private const string CustomerRoleName = "Customer";
    private const int MaxPhotosPerMessage = 5;

    private readonly CustomerProfileCrudService _customerProfileService;
    private readonly IValidator<SupportTicketCreateRequest> _createValidator;
    private readonly IValidator<SupportTicketMessageCreateRequest> _messageValidator;

    public SupportTicketsController(
        ISupportTicketService service,
        CustomerProfileCrudService customerProfileService,
        IValidator<SupportTicketCreateRequest> createValidator,
        IValidator<SupportTicketMessageCreateRequest> messageValidator) : base(service)
    {
        _customerProfileService = customerProfileService;
        _createValidator = createValidator;
        _messageValidator = messageValidator;
    }

    // Opens a ticket on behalf of the signed-in user. The CustomerId is never taken from the request
    // body (the DTO does not carry it): the service resolves it from the JWT user id and throws a
    // ClientException (-> 400) when the caller has no CustomerProfile, same trust model as
    // WaterMeterRequestsController.Create. Photos are optional and attach to the ticket's first
    // message. Every check that can reject the request (body, photo count, each file's size/type/
    // magic bytes) runs before the single service call, which stores ticket + message + photos in
    // one SaveChanges - so a 400 never leaves a half-created ticket behind.
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SupportTicketResponse>> Create(
        [FromForm] SupportTicketCreateRequest request,
        IFormFileCollection files)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        await _createValidator.ValidateAndThrowAsync(request);
        var photos = await ReadValidatedPhotosAsync(files);

        var result = await Service.CreateForUserAsync(userId, request.Subject, request.Body, photos);

        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    // Self-service inbox: pins search.CustomerId to the caller's own CustomerProfile.Id (resolved
    // from the JWT id) regardless of the query string, with no permission attribute - same pattern as
    // WaterMetersController's customer pinning. A caller with no CustomerProfile owns no tickets, so
    // they get an empty page rather than falling through to an unfiltered listing.
    [HttpGet("mine")]
    public async Task<ActionResult<PageResult<SupportTicketResponse>>> GetMine([FromQuery] SupportTicketSearchObject? search)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            return Ok(new PageResult<SupportTicketResponse>
            {
                Items = new List<SupportTicketResponse>(),
                TotalCount = search?.IncludeTotalCount == true ? 0 : null
            });
        }

        search ??= new SupportTicketSearchObject();
        search.CustomerId = customerId;
        return Ok(await Service.GetAllAsync(search));
    }

    // Admin-only unfiltered listing over the raw ticket table, same shape as
    // ActivityLogsController.GetAll / NotificationsController making the base listing Manage-gated.
    [RequirePermission(ManagePermission)]
    public override async Task<ActionResult<PageResult<SupportTicketResponse>>> GetAll([FromQuery] SupportTicketSearchObject? search)
    {
        return await base.GetAll(search);
    }

    // A SupportTickets.Manage holder reads any ticket's detail; otherwise only a customer may read,
    // and only their own ticket (404 - not Forbid - for another customer's ticket so the response
    // never confirms its id exists). A caller who is neither staff nor a customer is Forbidden, same
    // final branch as WaterMeterRequestsController.GetById.
    public override async Task<ActionResult<SupportTicketResponse>> GetById(int id)
    {
        if (HasManagePermission())
        {
            return await base.GetById(id);
        }

        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        if (!IsCustomer())
        {
            return Forbid();
        }

        try
        {
            var result = await Service.GetByIdAsync(id);
            var customerId = await ResolveCustomerProfileIdAsync(userId);
            if (customerId is null || result.CustomerId != customerId.Value)
            {
                return NotFound();
            }

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Appends a message to the thread. Authorized exactly like GetById (Manage or the owning
    // customer, else 404). isFromStaff is derived from the caller's permission, never the request.
    // AddMessageAsync enforces the "ticket must still be Open" rule and throws ClientException
    // (-> 400) before writing anything. Photos are optional and attach to the new message; like
    // Create, all of them are validated before the one service call that stores message + photos.
    [HttpPost("{id:int}/messages")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupportTicketMessageResponse>> AddMessage(
        int id,
        [FromForm] SupportTicketMessageCreateRequest request,
        IFormFileCollection files)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var (_, error) = await AuthorizeTicketAccessAsync(id, userId);
        if (error is not null)
        {
            return error;
        }

        await _messageValidator.ValidateAndThrowAsync(request);
        var photos = await ReadValidatedPhotosAsync(files);

        SupportTicketMessageResponse message;
        try
        {
            // The response's Photos are mapped from the photo entities this call actually saved.
            message = await Service.AddMessageAsync(id, userId, HasManagePermission(), request.Body, photos);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }

        return CreatedAtAction(nameof(GetById), new { id }, message);
    }

    // Serves a message photo's raw bytes. Same authorization as GetById (Manage or the owning
    // customer, else 404). GetPhotoAsync scopes the lookup to the full ticket -> message -> photo
    // chain, so a photo id from another ticket/message can never be read through this ticket.
    [HttpGet("{id:int}/messages/{messageId:int}/photos/{photoId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPhoto(int id, int messageId, int photoId)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var (_, error) = await AuthorizeTicketAccessAsync(id, userId);
        if (error is not null)
        {
            return error;
        }

        try
        {
            var photo = await Service.GetPhotoAsync(id, messageId, photoId);
            return File(photo.Data, photo.ContentType, photo.FileName);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost("{id:int}/close")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupportTicketResponse>> Close(int id)
    {
        // The acting staff member comes from the JWT (never the request); the service keeps them out
        // of the customer's "ticket closed" notification.
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await Service.CloseAsync(id, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost("{id:int}/reopen")]
    [RequirePermission(ManagePermission)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupportTicketResponse>> Reopen(int id)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await Service.ReopenAsync(id, userId));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Shared ownership gate for the message/photo sub-routes: mirrors GetById. A Manage holder passes
    // (404 only for a genuinely missing ticket); otherwise the caller must own the ticket (its
    // CustomerId == their CustomerProfile.Id) or gets 404 (not Forbid), so the response never
    // confirms the id exists. Uses GetOwnershipAsync's projection rather than the full detail load.
    private async Task<(SupportTicketOwnership? Ownership, ActionResult? Error)> AuthorizeTicketAccessAsync(int id, int userId)
    {
        var ownership = await Service.GetOwnershipAsync(id);
        if (ownership is null)
        {
            return (null, NotFound());
        }

        if (HasManagePermission())
        {
            return (ownership, null);
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null || ownership.CustomerId != customerId.Value)
        {
            return (null, NotFound());
        }

        return (ownership, null);
    }

    // Checks the photo count, then reads and validates EVERY file (ImageUploadHelper: size cap,
    // type whitelist, magic bytes) into memory. Throws ClientException (-> 400) on the first bad
    // file, which - since this runs before any service call - means nothing has been written yet.
    private static async Task<List<SupportTicketPhotoUpload>> ReadValidatedPhotosAsync(IFormFileCollection? files)
    {
        var photos = new List<SupportTicketPhotoUpload>();
        if (files is null)
        {
            return photos;
        }

        if (files.Count > MaxPhotosPerMessage)
        {
            throw new ClientException("A support ticket message can have at most 5 photos.");
        }

        foreach (var file in files)
        {
            var (data, contentType) = await ImageUploadHelper.ReadValidatedImageAsync(file);
            photos.Add(new SupportTicketPhotoUpload(data, contentType, file.FileName));
        }

        return photos;
    }

    private async Task<int?> ResolveCustomerProfileIdAsync(int userId)
    {
        var page = await _customerProfileService.GetAllAsync(new CustomerProfileSearchObject
        {
            UserId = userId,
            PageSize = 1
        });

        return page.Items.FirstOrDefault()?.Id;
    }

    private bool HasManagePermission()
    {
        return User.Claims.Any(claim =>
            claim.Type == ClaimNames.Permission &&
            string.Equals(claim.Value, ManagePermission, StringComparison.OrdinalIgnoreCase));
    }

    private bool IsCustomer()
    {
        var role = User.FindFirst(ClaimNames.UserRole)?.Value;
        return string.Equals(role, CustomerRoleName, StringComparison.OrdinalIgnoreCase);
    }

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
