using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace AquaFlow.Services.Payments;

// Stripe-backed saved cards. Only display data (brand, last4, expiry) ever leaves Stripe; AquaFlow stores
// nothing but CustomerProfile.StripeCustomerId.
public class StripePaymentCardService : IPaymentCardService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly CustomerService _customerService = new();
    private readonly PaymentMethodService _paymentMethodService = new();
    private readonly SetupIntentService _setupIntentService = new();
    private readonly EphemeralKeyService _ephemeralKeyService = new();

    public StripePaymentCardService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public bool IsSupported => true;

    public async Task<string> EnsureStripeCustomerAsync(int customerProfileId)
    {
        var profile = await _dbContext.CustomerProfiles
            .Include(p => p.User)
            .FirstOrDefaultAsync(p => p.Id == customerProfileId)
            ?? throw new KeyNotFoundException($"Customer profile with id {customerProfileId} was not found.");

        if (!string.IsNullOrWhiteSpace(profile.StripeCustomerId))
        {
            return profile.StripeCustomerId;
        }

        // The idempotency key makes two concurrent first-time calls resolve to the same Stripe Customer
        // instead of creating a duplicate that the unique index would then reject.
        var customer = await _customerService.CreateAsync(
            new CustomerCreateOptions
            {
                Email = profile.User?.Email,
                Name = $"{profile.FirstName} {profile.LastName}".Trim(),
                Metadata = new Dictionary<string, string>
                {
                    { "customerProfileId", profile.Id.ToString() }
                }
            },
            new RequestOptions { IdempotencyKey = $"aquaflow-customer-profile-{profile.Id}" });

        profile.StripeCustomerId = customer.Id;
        await _dbContext.SaveChangesAsync();
        return customer.Id;
    }

    public async Task<List<PaymentCardResponse>> ListAsync(int customerProfileId)
    {
        var stripeCustomerId = await GetStripeCustomerIdAsync(customerProfileId);
        if (stripeCustomerId == null)
        {
            return new List<PaymentCardResponse>();
        }

        var methods = await _paymentMethodService.ListAsync(new PaymentMethodListOptions
        {
            Customer = stripeCustomerId,
            Type = "card",
            Limit = 100
        });

        return methods.Data
            .Where(method => method.Card != null)
            .Select(method => new PaymentCardResponse
            {
                Id = method.Id,
                Brand = method.Card.Brand,
                Last4 = method.Card.Last4,
                ExpMonth = (int)method.Card.ExpMonth,
                ExpYear = (int)method.Card.ExpYear
            })
            .ToList();
    }

    public async Task<CardSetupResponse> CreateSetupAsync(int customerProfileId)
    {
        var stripeCustomerId = await EnsureStripeCustomerAsync(customerProfileId);

        var setupIntent = await _setupIntentService.CreateAsync(new SetupIntentCreateOptions
        {
            Customer = stripeCustomerId,
            Usage = "off_session",
            PaymentMethodTypes = new List<string> { "card" }
        });

        return new CardSetupResponse
        {
            SetupIntentClientSecret = setupIntent.ClientSecret,
            StripeCustomerId = stripeCustomerId,
            EphemeralKeySecret = await CreateEphemeralKeyAsync(stripeCustomerId)
        };
    }

    public async Task DeleteAsync(int customerProfileId, string paymentMethodId)
    {
        var stripeCustomerId = await GetStripeCustomerIdAsync(customerProfileId);
        if (stripeCustomerId == null)
        {
            throw new KeyNotFoundException("Payment card was not found.");
        }

        Stripe.PaymentMethod method;
        try
        {
            method = await _paymentMethodService.GetAsync(paymentMethodId);
        }
        catch (StripeException ex) when (ex.HttpStatusCode == System.Net.HttpStatusCode.NotFound)
        {
            throw new KeyNotFoundException("Payment card was not found.");
        }

        // Same signal for "not yours" and "does not exist" so card ids cannot be probed.
        if (!string.Equals(method.CustomerId, stripeCustomerId, StringComparison.Ordinal))
        {
            throw new KeyNotFoundException("Payment card was not found.");
        }

        await _paymentMethodService.DetachAsync(paymentMethodId);
    }

    // The ephemeral key must be created with the API version the client SDK speaks; the Stripe.net default
    // (StripeConfiguration.ApiVersion) is used, which matches what flutter_stripe 13.x pins to.
    public async Task<string> CreateEphemeralKeyAsync(string stripeCustomerId)
    {
        var key = await _ephemeralKeyService.CreateAsync(
            new EphemeralKeyCreateOptions { Customer = stripeCustomerId, StripeVersion = StripeConfiguration.ApiVersion });
        return key.Secret;
    }

    private async Task<string?> GetStripeCustomerIdAsync(int customerProfileId)
    {
        var profile = await _dbContext.CustomerProfiles
            .AsNoTracking()
            .Where(p => p.Id == customerProfileId)
            .Select(p => new { p.StripeCustomerId })
            .FirstOrDefaultAsync()
            ?? throw new KeyNotFoundException($"Customer profile with id {customerProfileId} was not found.");

        return string.IsNullOrWhiteSpace(profile.StripeCustomerId) ? null : profile.StripeCustomerId;
    }
}
