using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class CustomerProfileService
    : EfCrudService<CustomerProfile, CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public CustomerProfileService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<CustomerProfileInsertRequest>> insertValidators,
        IEnumerable<IValidator<CustomerProfileUpdateRequest>> updateValidators,
        IEnumerable<IValidator<CustomerProfilePatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    private const string CustomerCodePrefix = "CUS-";

    protected override async Task BeforeInsertAsync(CustomerProfileInsertRequest request)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureUserDoesNotHaveCustomerProfileAsync(request.UserId);

        // CustomerCode is never client-supplied; always assign a fresh generated one.
        request.CustomerCode = await GenerateCustomerCodeAsync();
    }

    protected override async Task BeforeUpdateAsync(int id, CustomerProfileUpdateRequest request, CustomerProfile entity)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureUserDoesNotHaveCustomerProfileAsync(request.UserId, id);

        // CustomerCode is immutable once assigned; ignore whatever the caller sent.
        request.CustomerCode = entity.CustomerCode;
    }

    protected override async Task BeforePatchAsync(int id, CustomerProfilePatchRequest request, CustomerProfile entity)
    {
        // CustomerCode is immutable once assigned; ignore whatever the caller sent.
        request.CustomerCode = null;

        if (!request.UserId.HasValue)
        {
            return;
        }

        await EnsureUserExistsAsync(request.UserId.Value);
        await EnsureUserDoesNotHaveCustomerProfileAsync(request.UserId.Value, id);
    }

    private async Task<string> GenerateCustomerCodeAsync()
    {
        var existingCodes = await _dbContext.CustomerProfiles
            .Where(profile => profile.CustomerCode.StartsWith(CustomerCodePrefix))
            .Select(profile => profile.CustomerCode)
            .ToListAsync();

        var nextNumber = existingCodes
            .Select(code => int.TryParse(code.AsSpan(CustomerCodePrefix.Length), out var number) ? number : 0)
            .DefaultIfEmpty(0)
            .Max() + 1;

        return $"{CustomerCodePrefix}{nextNumber:D4}";
    }

    private async Task EnsureUserExistsAsync(int userId)
    {
        if (!await _dbContext.Users.AnyAsync(user => user.Id == userId))
        {
            throw new ClientException($"User with id {userId} was not found.");
        }
    }

    private async Task EnsureUserDoesNotHaveCustomerProfileAsync(int userId, int? excludedId = null)
    {
        var alreadyExists = await _dbContext.CustomerProfiles.AnyAsync(profile =>
            profile.UserId == userId &&
            profile.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException($"User with id {userId} already has a customer profile.");
        }
    }
}
