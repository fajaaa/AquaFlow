using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class UserService : BaseCRUDService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>, IUserService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly ICryptoService _cryptoService;

    public UserService(
        AquaFlowDbContext dbContext,
        ICryptoService cryptoService,
        IMapper mapper,
        IEnumerable<IValidator<UserInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserPatchRequest>> patchValidators)
        : base(mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _cryptoService = cryptoService;
    }

    protected override IQueryable<User> GetDataSource() =>
        _dbContext.Users.AsNoTracking().Include(u => u.UserRole);

    protected override IList<User> GetWritableDataSource() =>
        throw new NotSupportedException($"{nameof(UserService)} writes through Entity Framework.");

    protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (!string.IsNullOrWhiteSpace(search.Email))
        {
            query = query.Where(u => u.Email.Contains(search.Email));
        }

        if (search.UserRoleId.HasValue)
        {
            query = query.Where(u => u.UserRoleId == search.UserRoleId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.UserRole))
        {
            query = query.Where(u => u.UserRole != null && u.UserRole.Name.Contains(search.UserRole));
        }

        if (search.IsActive.HasValue)
        {
            query = query.Where(u => u.IsActive == search.IsActive.Value);
        }

        return query;
    }

    protected override User MapInsertRequestToEntity(UserInsertRequest request)
    {
        var entity = Mapper.Map<User>(request);
        SetPassword(entity, request.Password);
        return entity;
    }

    public override async Task<UserResponse> InsertAsync(UserInsertRequest request)
    {
        await ValidateInsertAsync(request);
        await EnsureUniqueEmailAsync(request.Email);

        var entity = MapInsertRequestToEntity(request);
        entity.CreatedAt = DateTime.UtcNow;

        _dbContext.Users.Add(entity);
        await _dbContext.SaveChangesAsync();
        await _dbContext.Entry(entity).Reference(u => u.UserRole).LoadAsync();

        return Mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse> PatchAsync(int id, UserPatchRequest request)
    {
        await ValidatePatchAsync(request);

        var entity = await _dbContext.Users.Include(u => u.UserRole).FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        if (request.Email != null)
        {
            await EnsureUniqueEmailAsync(request.Email, id);
        }

        Mapper.Map(request, entity);
        if (request.Password != null)
        {
            SetPassword(entity, request.Password);
        }

        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await ReloadUserRoleAsync(entity);

        return Mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
    {
        await ValidateUpdateAsync(request);

        var entity = await _dbContext.Users.Include(u => u.UserRole).FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        await EnsureUniqueEmailAsync(request.Email, id);

        Mapper.Map(request, entity);
        SetPassword(entity, request.Password);
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await ReloadUserRoleAsync(entity);

        return Mapper.Map<UserResponse>(entity);
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        _dbContext.Users.Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    public async Task<UserSensitiveResponse?> GetByEmailAsync(string email)
    {
        var user = await _dbContext.Users.Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Email == email);

        return user == null ? null : Mapper.Map<UserSensitiveResponse>(user);
    }

    public async Task UpdateLastLoginAtAsync(int id)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        user.LastLoginAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureUniqueEmailAsync(string email, int? excludedId = null)
    {
        var alreadyExists = await _dbContext.Users.AnyAsync(u =>
            u.Email == email && u.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException($"User with email '{email}' already exists.");
        }
    }

    private void SetPassword(User entity, string password)
    {
        var salt = _cryptoService.GenerateSalt();
        entity.PasswordSalt = salt;
        entity.PasswordHash = _cryptoService.GenerateHash(password, salt);
    }

    private async Task ReloadUserRoleAsync(User entity)
    {
        entity.UserRole = await _dbContext.UserRoles.FindAsync(entity.UserRoleId);
    }
}
