using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using FluentValidation;

using CustomerProfileCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CustomerProfileResponse, AquaFlow.Model.SearchObjects.CustomerProfileSearchObject, AquaFlow.Model.Requests.CustomerProfileInsertRequest, AquaFlow.Model.Requests.CustomerProfileUpdateRequest, AquaFlow.Model.Requests.CustomerProfilePatchRequest>;

namespace AquaFlow.Services;

// Orchestrates registration across three aggregates (User, CustomerProfile, UserPreference) rather
// than living in UserService, so UserService stays a plain User CRUD service and each step reuses
// its owner's existing rules unchanged: UserService.InsertAsync (insert validator, unique email,
// password hashing), CustomerProfileService.InsertAsync (name capitalization, CustomerCode
// generation) and UserPreferenceService.UpdateAsync (upsert). All of them share this request's
// scoped AquaFlowDbContext, so their individual SaveChanges calls all enlist in the one
// IDbContextTransaction opened here - same pattern as NotificationService.InsertAsync.
public class RegistrationService : IRegistrationService
{
    // Seeded "Customer" role (AquaFlowDbContextSeed.SeedUserRoles). Public self-registration
    // must never let the caller pick their own role, so it is always a Customer.
    private const int DefaultCustomerRoleId = 3;
    private const string DefaultTheme = "light";
    private const string DefaultLanguage = "bs";

    private readonly AquaFlowDbContext _dbContext;
    private readonly IUserService _userService;
    private readonly CustomerProfileCrudService _customerProfileService;
    private readonly IUserPreferenceService _userPreferenceService;
    private readonly IValidator<UserRegisterRequest> _registerValidator;

    public RegistrationService(
        AquaFlowDbContext dbContext,
        IUserService userService,
        CustomerProfileCrudService customerProfileService,
        IUserPreferenceService userPreferenceService,
        IValidator<UserRegisterRequest> registerValidator)
    {
        _dbContext = dbContext;
        _userService = userService;
        _customerProfileService = customerProfileService;
        _userPreferenceService = userPreferenceService;
        _registerValidator = registerValidator;
    }

    public async Task<UserResponse> RegisterCustomerAsync(UserRegisterRequest request)
    {
        // Everything the caller can get wrong is checked before the first write: the register
        // validator covers email format, password length, phone, the profile's first/last name
        // (same rules as CustomerProfileInsertValidator) and the Theme whitelist; the unique-email
        // check runs inside UserService.InsertAsync before its SaveChanges, and that insert is the
        // first write of the transaction. What can still fail after it is the DB itself (e.g. two
        // concurrent registrations generating the same CustomerCode hit its unique index) - the
        // transaction is what keeps such a failure from leaving an orphaned User behind.
        await _registerValidator.ValidateAndThrowAsync(request);

        var userRequest = new UserInsertRequest
        {
            Email = request.Email,
            Password = request.Password,
            Phone = request.Phone,
            UserRoleId = DefaultCustomerRoleId,
            IsActive = true
        };
        var preferenceRequest = new UserPreferenceUpdateRequest
        {
            Theme = string.IsNullOrEmpty(request.Theme) ? DefaultTheme : request.Theme,
            Language = DefaultLanguage,
            ReceiveEmailNotifications = true,
            ReceivePushNotifications = true
        };

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        try
        {
            var user = await _userService.InsertAsync(userRequest);

            await _customerProfileService.InsertAsync(new CustomerProfileInsertRequest
            {
                UserId = user.Id,
                FirstName = request.FirstName,
                LastName = request.LastName
            });

            await _userPreferenceService.UpdateAsync(user.Id, preferenceRequest);

            // Re-read through UserService so FirstName/LastName come from the new CustomerProfile
            // (the InsertAsync response predates the profile). Done before the commit so a failure
            // here also rolls back instead of answering with an error for a persisted account.
            var result = await _userService.GetByIdAsync(user.Id);

            await transaction.CommitAsync();
            return result;
        }
        catch
        {
            await transaction.RollbackAsync();
            // The rolled-back rows are still tracked as Unchanged; drop them so nothing else in this
            // scope (e.g. a later SaveChanges) treats them as existing.
            _dbContext.ChangeTracker.Clear();
            throw;
        }
    }
}
