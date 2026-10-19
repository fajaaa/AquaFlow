using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using AquaFlow.Services.Tests.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.Services.Tests.Registration;

// Unlike most of this project, these tests run against SQLite in-memory (SqliteTestDatabase)
// instead of the EF InMemory provider: InMemory ignores transactions, so it cannot show that a
// failed registration is rolled back.
public sealed class RegistrationServiceTests : IDisposable
{
    private readonly SqliteTestDatabase _database = new();

    public void Dispose() => _database.Dispose();

    [Fact]
    public async Task RegisterCustomerAsync_ValidRequest_StoresUserProfileAndPreference()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        var result = await service.RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba", theme: "dark"));

        Assert.Equal("Amina", result.FirstName);
        Assert.Equal("Hodzic", result.LastName);
        Assert.Equal("Customer", result.UserRole);

        await using var verify = CreateContext();
        var user = await verify.Users.SingleAsync(u => u.Email == "nova.korisnica@aquaflow.ba");
        Assert.Equal(3, user.UserRoleId);
        var profile = await verify.CustomerProfiles.SingleAsync(p => p.UserId == user.Id);
        Assert.StartsWith("CUS-", profile.CustomerCode);
        Assert.Equal("Amina", profile.FirstName);
        var preference = await verify.UserPreferences.SingleAsync(p => p.UserId == user.Id);
        Assert.Equal("dark", preference.Theme);
        Assert.Equal("bs", preference.Language);
    }

    [Fact]
    public async Task RegisterCustomerAsync_DuplicateEmail_ThrowsClientException_AndWritesNothing()
    {
        var before = await CountRowsAsync();
        await using var context = CreateContext();
        var service = CreateService(context);

        // Seeded admin account (AquaFlowDbContextSeed).
        await Assert.ThrowsAsync<ClientException>(
            () => service.RegisterCustomerAsync(ValidRequest("kenan.fajic@aquaflow.ba")));

        Assert.Equal(before, await CountRowsAsync());
    }

    [Fact]
    public async Task RegisterCustomerAsync_InvalidTheme_ThrowsValidationException_AndWritesNothing()
    {
        var before = await CountRowsAsync();
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ValidationException>(
            () => service.RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba", theme: "purple")));

        Assert.Equal(before, await CountRowsAsync());
    }

    // Step 2 (CustomerProfile) fails after the User and the profile were already saved inside the
    // transaction: the rollback must remove both, so the email stays free for the next attempt.
    [Fact]
    public async Task RegisterCustomerAsync_ProfileStepFails_RollsBackUser()
    {
        var before = await CountRowsAsync();
        await using var context = CreateContext();
        var service = CreateService(context, failProfileStep: true);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba")));

        Assert.Equal(before, await CountRowsAsync());
        await using var verify = CreateContext();
        Assert.False(await verify.Users.AnyAsync(u => u.Email == "nova.korisnica@aquaflow.ba"));
    }

    // Step 3 (UserPreference) fails after all three rows were saved inside the transaction.
    [Fact]
    public async Task RegisterCustomerAsync_PreferenceStepFails_RollsBackUserAndProfile()
    {
        var before = await CountRowsAsync();
        await using var context = CreateContext();
        var service = CreateService(context, failPreferenceStep: true);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba")));

        Assert.Equal(before, await CountRowsAsync());
    }

    // The point of the rollback: after a failed attempt the same email registers successfully
    // instead of hitting "already exists" on a half-created account.
    [Fact]
    public async Task RegisterCustomerAsync_RetryAfterFailedAttempt_Succeeds()
    {
        await using (var failingContext = CreateContext())
        {
            var failing = CreateService(failingContext, failPreferenceStep: true);
            await Assert.ThrowsAsync<InvalidOperationException>(
                () => failing.RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba")));
        }

        await using var context = CreateContext();
        var result = await CreateService(context).RegisterCustomerAsync(ValidRequest("nova.korisnica@aquaflow.ba"));

        Assert.True(result.Id > 0);
    }

    private AquaFlowDbContext CreateContext() => _database.CreateContext();

    // Counted on a fresh context so the result reflects what is committed in the database, not what
    // some other context still tracks.
    private async Task<(int Users, int Profiles, int Preferences)> CountRowsAsync()
    {
        await using var context = CreateContext();
        return (
            await context.Users.CountAsync(),
            await context.CustomerProfiles.CountAsync(),
            await context.UserPreferences.CountAsync());
    }

    private static UserRegisterRequest ValidRequest(string email, string theme = "light") => new()
    {
        Email = email,
        Password = "Lozinka1",
        Phone = "061 123 456",
        FirstName = "amina",
        LastName = "hodzic",
        Theme = theme
    };

    private static RegistrationService CreateService(
        AquaFlowDbContext context,
        bool failProfileStep = false,
        bool failPreferenceStep = false)
    {
        // Mirrors the User -> UserResponse flatten config in Program.cs (role name, and the name
        // taken from the CustomerProfile when one exists).
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<User, UserResponse>()
            .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name)
            .Map(destination => destination.FirstName, source => source.CustomerProfile == null ? source.FirstName : source.CustomerProfile.FirstName)
            .Map(destination => destination.LastName, source => source.CustomerProfile == null ? source.LastName : source.CustomerProfile.LastName);
        IMapper mapper = new Mapper(mapperConfig);

        var userService = new UserService(
            context,
            new CryptoService(),
            TestSecurityStamps.Create(context),
            mapper,
            new IValidator<UserInsertRequest>[] { new UserInsertValidator() },
            Array.Empty<IValidator<UserUpdateRequest>>(),
            Array.Empty<IValidator<UserPatchRequest>>());

        CustomerProfileCrudService profileService = new CustomerProfileService(
            context,
            mapper,
            new IValidator<CustomerProfileInsertRequest>[] { new CustomerProfileInsertValidator() },
            Array.Empty<IValidator<CustomerProfileUpdateRequest>>(),
            Array.Empty<IValidator<CustomerProfilePatchRequest>>());
        if (failProfileStep)
        {
            profileService = new FailingCustomerProfileService(profileService);
        }

        IUserPreferenceService preferenceService = new UserPreferenceService(context);
        if (failPreferenceStep)
        {
            preferenceService = new FailingUserPreferenceService(preferenceService);
        }

        return new RegistrationService(context, userService, profileService, preferenceService, new UserRegisterValidator());
    }
}
