using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Payments;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

// Customer self-service saved cards (Stripe). Gated on Invoices.Pay (Customer only) and always scoped to
// the caller's own CustomerProfile, resolved from the JWT Id claim exactly like InvoicesController.Checkout:
// no profile id is ever taken from the client, so there is no way to touch another customer's cards.
[Authorize]
[ApiController]
[Route("[controller]")]
public class PaymentCardsController : ControllerBase
{
    private readonly IPaymentCardService _cardService;
    private readonly CustomerProfileCrudService _customerProfileService;

    public PaymentCardsController(IPaymentCardService cardService, CustomerProfileCrudService customerProfileService)
    {
        _cardService = cardService;
        _customerProfileService = customerProfileService;
    }

    [RequirePermission("Invoices.Pay")]
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentCardsResponse>> GetAll()
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            return NotFound();
        }

        return Ok(new PaymentCardsResponse
        {
            IsSupported = _cardService.IsSupported,
            Items = await _cardService.ListAsync(customerId.Value)
        });
    }

    [RequirePermission("Invoices.Pay")]
    [HttpPost("setup")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CardSetupResponse>> Setup()
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            return NotFound();
        }

        return Ok(await _cardService.CreateSetupAsync(customerId.Value));
    }

    // 404 both for an unknown card and for another customer's card - same signal, so ids cannot be probed.
    [RequirePermission("Invoices.Pay")]
    [HttpDelete("{paymentMethodId}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(string paymentMethodId)
    {
        if (!TryGetCurrentUserId(out var userId))
        {
            return Unauthorized();
        }

        var customerId = await ResolveCustomerProfileIdAsync(userId);
        if (customerId is null)
        {
            return NotFound();
        }

        try
        {
            await _cardService.DeleteAsync(customerId.Value, paymentMethodId);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
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

    private bool TryGetCurrentUserId(out int userId)
    {
        var claimValue = User.FindFirst(ClaimNames.Id)?.Value;
        return int.TryParse(claimValue, out userId);
    }
}
