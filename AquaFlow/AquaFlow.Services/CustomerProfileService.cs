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
    : EfCrudService<CustomerProfile, CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest>
{
    private readonly AquaFlowDbContext _dbContext;

    public CustomerProfileService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<CustomerProfileInsertRequest>> insertValidators,
        IEnumerable<IValidator<CustomerProfileUpdateRequest>> updateValidators)
        : base(dbContext, mapper, insertValidators, updateValidators)
    {
        _dbContext = dbContext;
    }

    protected override async Task BeforeInsertAsync(CustomerProfileInsertRequest request)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureUserDoesNotHaveCustomerProfileAsync(request.UserId);
    }

    protected override async Task BeforeUpdateAsync(int id, CustomerProfileUpdateRequest request, CustomerProfile entity)
    {
        await EnsureUserExistsAsync(request.UserId);
        await EnsureUserDoesNotHaveCustomerProfileAsync(request.UserId, id);
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
