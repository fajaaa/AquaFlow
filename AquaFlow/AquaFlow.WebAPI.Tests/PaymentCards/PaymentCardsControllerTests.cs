using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Payments;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using AquaFlow.WebAPI.Tests.Invoices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.PaymentCards;

// PaymentCardsController only resolves the caller's own CustomerProfile (from the JWT Id claim, like
// InvoicesController.Checkout) and delegates to IPaymentCardService; the Stripe calls themselves are
// never made here - FakePaymentCardService stands in for them.
public class PaymentCardsControllerTests
{
    [Theory]
    [InlineData(nameof(PaymentCardsController.GetAll))]
    [InlineData(nameof(PaymentCardsController.Setup))]
    [InlineData(nameof(PaymentCardsController.Delete))]
    public void Actions_RequireInvoicesPayPermission(string actionName)
    {
        var attribute = typeof(PaymentCardsController)
            .GetMethod(actionName)!
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        Assert.Contains("Invoices.Pay", Assert.IsType<string[]>(attribute!.Arguments![0]));
    }

    [Fact]
    public async Task GetAll_ReturnsOnlyCallersOwnCards()
    {
        var cards = new FakePaymentCardService();
        cards.AddCard(10, "pm_mine");
        cards.AddCard(20, "pm_other");
        var controller = CreateController(userId: 1, profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }], cards);

        var result = await controller.GetAll();

        var response = Assert.IsType<PaymentCardsResponse>(Assert.IsType<OkObjectResult>(result.Result).Value);
        Assert.True(response.IsSupported);
        Assert.Equal("pm_mine", Assert.Single(response.Items).Id);
        Assert.Equal(10, Assert.Single(cards.ListCalls));
    }

    [Fact]
    public async Task GetAll_UnsupportedProvider_ReportsIsSupportedFalseWithNoItems()
    {
        var cards = new FakePaymentCardService { IsSupported = false };
        var controller = CreateController(userId: 1, profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }], cards);

        var result = await controller.GetAll();

        var response = Assert.IsType<PaymentCardsResponse>(Assert.IsType<OkObjectResult>(result.Result).Value);
        Assert.False(response.IsSupported);
        Assert.Empty(response.Items);
    }

    [Fact]
    public async Task Setup_UsesCallersOwnProfile()
    {
        var cards = new FakePaymentCardService();
        var controller = CreateController(
            userId: 2,
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }, new CustomerProfileResponse { Id = 20, UserId = 2 }],
            cards);

        var result = await controller.Setup();

        var response = Assert.IsType<CardSetupResponse>(Assert.IsType<OkObjectResult>(result.Result).Value);
        Assert.Equal("cus_20", response.StripeCustomerId);
        Assert.Equal(20, Assert.Single(cards.SetupCalls));
    }

    [Fact]
    public async Task Delete_OwnCard_ReturnsNoContent()
    {
        var cards = new FakePaymentCardService();
        cards.AddCard(10, "pm_mine");
        var controller = CreateController(userId: 1, profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }], cards);

        var result = await controller.Delete("pm_mine");

        Assert.IsType<NoContentResult>(result);
        Assert.Equal((10, "pm_mine"), Assert.Single(cards.DeleteCalls));
    }

    [Fact]
    public async Task Delete_OtherCustomersCard_ReturnsNotFoundAndLeavesItUntouched()
    {
        var cards = new FakePaymentCardService();
        cards.AddCard(20, "pm_other");
        var controller = CreateController(userId: 1, profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }], cards);

        var result = await controller.Delete("pm_other");

        Assert.IsType<NotFoundResult>(result);
        // The delete was attempted against the caller's profile (10), never the owner's (20).
        Assert.Equal((10, "pm_other"), Assert.Single(cards.DeleteCalls));
        Assert.Single(await cards.ListAsync(20));
    }

    [Fact]
    public async Task Delete_UnsupportedProvider_PropagatesClientException()
    {
        var controller = CreateController(
            userId: 1,
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            new NotSupportedPaymentCardService());

        await Assert.ThrowsAsync<ClientException>(() => controller.Delete("pm_any"));
    }

    [Fact]
    public async Task Actions_CustomerWithoutProfile_ReturnNotFound()
    {
        var cards = new FakePaymentCardService();
        var controller = CreateController(userId: 1, profiles: [], cards);

        Assert.IsType<NotFoundResult>((await controller.GetAll()).Result);
        Assert.IsType<NotFoundResult>((await controller.Setup()).Result);
        Assert.IsType<NotFoundResult>(await controller.Delete("pm_any"));
        Assert.Empty(cards.ListCalls);
        Assert.Empty(cards.SetupCalls);
        Assert.Empty(cards.DeleteCalls);
    }

    [Fact]
    public async Task Actions_MissingIdClaim_ReturnUnauthorized()
    {
        var controller = CreateController(userId: null, profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }], new FakePaymentCardService());

        Assert.IsType<UnauthorizedResult>((await controller.GetAll()).Result);
        Assert.IsType<UnauthorizedResult>((await controller.Setup()).Result);
        Assert.IsType<UnauthorizedResult>(await controller.Delete("pm_any"));
    }

    private static PaymentCardsController CreateController(
        int? userId,
        IEnumerable<CustomerProfileResponse> profiles,
        IPaymentCardService cardService)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        return new PaymentCardsController(cardService, new FakeCustomerProfileCrudService(profiles))
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(new ClaimsIdentity(claims, "test")) }
            }
        };
    }
}
