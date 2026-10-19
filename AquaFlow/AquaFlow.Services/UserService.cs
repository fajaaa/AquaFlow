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
    private readonly ISecurityStampService _securityStampService;

    public UserService(
        AquaFlowDbContext dbContext,
        ICryptoService cryptoService,
        ISecurityStampService securityStampService,
        IMapper mapper,
        IEnumerable<IValidator<UserInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserPatchRequest>> patchValidators)
        : base(mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _cryptoService = cryptoService;
        _securityStampService = securityStampService;
    }

    protected override IQueryable<User> GetDataSource() =>
        _dbContext.Users
            .AsNoTracking()
            .Where(u => !u.IsDeleted)
            .Include(u => u.UserRole)
            .Include(u => u.CustomerProfile);

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

        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(u =>
                (u.CustomerProfile != null &&
                 (u.CustomerProfile.FirstName.Contains(search.Name) || u.CustomerProfile.LastName.Contains(search.Name))) ||
                u.FirstName.Contains(search.Name) || u.LastName.Contains(search.Name));
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

        var entity = await _dbContext.Users
            .Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        if (request.Email != null)
        {
            await EnsureUniqueEmailAsync(request.Email, id);
        }

        var wasActive = entity.IsActive;
        var previousRoleId = entity.UserRoleId;

        Mapper.Map(request, entity);
        if (request.Password != null)
        {
            SetPassword(entity, request.Password);
        }

        if (MustRevokeSessions(entity, passwordChanged: request.Password != null, wasActive, previousRoleId))
        {
            await RevokeSessionsAsync(entity);
        }

        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await ReloadUserRoleAsync(entity);

        return Mapper.Map<UserResponse>(entity);
    }

    public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
    {
        await ValidateUpdateAsync(request);

        var entity = await _dbContext.Users
            .Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        await EnsureUniqueEmailAsync(request.Email, id);

        var wasActive = entity.IsActive;
        var previousRoleId = entity.UserRoleId;

        Mapper.Map(request, entity);
        // PUT always carries a (validated, non-empty) password and always re-hashes it, so a PUT
        // always counts as a password reset and always ends the user's sessions.
        SetPassword(entity, request.Password);

        if (MustRevokeSessions(entity, passwordChanged: true, wasActive, previousRoleId))
        {
            await RevokeSessionsAsync(entity);
        }

        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await ReloadUserRoleAsync(entity);

        return Mapper.Map<UserResponse>(entity);
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        // Ends every session of the deleted account: its refresh tokens (login artifacts, not
        // business data; RefreshToken.UserId is a Restrict FK) and every access token in flight.
        await RevokeSessionsAsync(entity);

        entity.IsDeleted = true;
        entity.IsActive = false;
        entity.DeletedAt = DateTime.UtcNow;
        entity.UpdatedAt = entity.DeletedAt;

        await _dbContext.SaveChangesAsync();
    }

    public async Task<UserResponse> UpdateOwnAccountAsync(int id, AccountUpdateRequest request)
    {
        var entity = await _dbContext.Users
            .Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        await EnsureUniqueEmailAsync(request.Email, id);

        // Only contact data is self-editable; role, active state and password are
        // left untouched so a user can never escalate their own privileges here.
        entity.Email = request.Email;
        entity.Phone = request.Phone;
        if (request.FirstName != null)
        {
            entity.FirstName = request.FirstName;
        }
        if (request.LastName != null)
        {
            entity.LastName = request.LastName;
        }
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        await ReloadUserRoleAsync(entity);

        return Mapper.Map<UserResponse>(entity);
    }

    public async Task ChangeOwnPasswordAsync(int id, AccountChangePasswordRequest request)
    {
        var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        if (!_cryptoService.Verify(entity.PasswordHash, entity.PasswordSalt, request.CurrentPassword))
        {
            throw new ClientException("Trenutna lozinka nije ispravna.");
        }

        SetPassword(entity, request.NewPassword);
        // Every device is signed out, including the one that made the change - a password change
        // is the user's way of ending a session they no longer trust.
        await RevokeSessionsAsync(entity);
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
    }

    public async Task<UserSensitiveResponse?> GetSensitiveByIdAsync(int id)
    {
        var user = await _dbContext.Users.AsNoTracking().Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);

        return user == null ? null : Mapper.Map<UserSensitiveResponse>(user);
    }

    public async Task<UserSensitiveResponse?> GetByEmailAsync(string email)
    {
        var user = await _dbContext.Users.Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Email == email && !u.IsDeleted);

        return user == null ? null : Mapper.Map<UserSensitiveResponse>(user);
    }

    public async Task UpdateLastLoginAtAsync(int id)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        user.LastLoginAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
    }

    private async Task EnsureUniqueEmailAsync(string email, int? excludedId = null)
    {
        var alreadyExists = await _dbContext.Users.AnyAsync(u =>
            !u.IsDeleted && u.Email == email && u.Id != excludedId);

        if (alreadyExists)
        {
            throw new ClientException($"User with email '{email}' already exists.");
        }
    }

    // Only security-relevant changes end sessions; editing email/phone/name never does.
    private static bool MustRevokeSessions(User entity, bool passwordChanged, bool wasActive, int previousRoleId) =>
        passwordChanged ||
        (wasActive && !entity.IsActive) ||
        entity.UserRoleId != previousRoleId;

    // The one place a user's sessions are ended: a new SecurityStamp (every access token issued
    // before it fails validation on its next request) plus removal of ALL refresh tokens (no
    // device can obtain a new access token). Only staged on the tracked entity - the caller's
    // SaveChangesAsync writes it in the same save as the change that caused it, and
    // SecurityStampService evicts its cached stamp once that save succeeds.
    private async Task RevokeSessionsAsync(User entity)
    {
        _securityStampService.Rotate(entity);

        var tokens = await _dbContext.RefreshTokens.Where(t => t.UserId == entity.Id).ToListAsync();
        _dbContext.RefreshTokens.RemoveRange(tokens);
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
