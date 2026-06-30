using System.Security.Cryptography;
using System.Text;
using AquaFlow.Model.Access;
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

    public UserService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<UserInsertRequest>> insertValidators,
        IEnumerable<IValidator<UserUpdateRequest>> updateValidators,
        IEnumerable<IValidator<UserPatchRequest>> patchValidators)
        : base(mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    protected override IEnumerable<User> GetDataSource() =>
        _dbContext.Users.Include(u => u.UserRole).AsEnumerable();

    protected override IList<User> GetWritableDataSource() =>
        _dbContext.Users.Include(u => u.UserRole).ToList();

    protected override IEnumerable<User> ApplyFilters(IEnumerable<User> query, UserSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (!string.IsNullOrWhiteSpace(search.Email))
        {
            query = query.Where(u => u.Email.Contains(search.Email, StringComparison.OrdinalIgnoreCase));
        }

        if (search.UserRoleId.HasValue)
        {
            query = query.Where(u => u.UserRoleId == search.UserRoleId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.UserRole))
        {
            query = query.Where(u => u.UserRole?.Name.Contains(search.UserRole, StringComparison.OrdinalIgnoreCase) == true);
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

    public async Task<UserResponse?> LoginAsync(UserLoginRequest request)
    {
        var user = await _dbContext.Users.Include(u => u.UserRole)
            .FirstOrDefaultAsync(u => u.Email == request.Email);

        if (user == null || !user.IsActive)
        {
            return null;
        }

        var hash = HashPassword(request.Password, user.PasswordSalt);
        if (hash != user.PasswordHash)
        {
            return null;
        }

        user.LastLoginAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return Mapper.Map<UserResponse>(user);
    }

    public async Task UpdateLastLoginAtAsync(int id)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new KeyNotFoundException($"User with id {id} was not found.");

        user.LastLoginAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
    }

    private static void SetPassword(User entity, string password)
    {
        var salt = GenerateSalt();
        entity.PasswordSalt = salt;
        entity.PasswordHash = HashPassword(password, salt);
    }

    private static string GenerateSalt()
    {
        using var rng = RandomNumberGenerator.Create();
        byte[] bytes = new byte[16];
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes);
    }

    private static string HashPassword(string password, string salt)
    {
        using var pbkdf2 = new Rfc2898DeriveBytes(
            password,
            Encoding.UTF8.GetBytes(salt),
            10000,
            HashAlgorithmName.SHA256);

        return Convert.ToBase64String(pbkdf2.GetBytes(20));
    }

    private async Task ReloadUserRoleAsync(User entity)
    {
        var reference = _dbContext.Entry(entity).Reference(u => u.UserRole);
        reference.IsLoaded = false;
        await reference.LoadAsync();
    }
}
