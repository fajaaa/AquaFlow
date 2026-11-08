using System.Text.RegularExpressions;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Generic CRUD for every codebook (lookup) table. Business tables reference a codebook by Code
// (FK with HasPrincipalKey), so the rules here protect what the code and the existing data depend on:
//  - Code is required, ^[A-Za-z][A-Za-z0-9]*$, at most 50 chars and unique (case-insensitive);
//  - IsSystem is never set by the client (inserted rows are always non-system);
//  - a system row cannot change its Code, cannot be deactivated and cannot be deleted;
//  - a non-system row can be deleted (or have its Code changed) only while no FK column uses it.
// Every violation is a ClientException (HTTP 400). Each concrete codebook only supplies IsInUseAsync.
public abstract class LookupService<TEntity>
    : EfCrudService<TEntity, LookupResponse, LookupSearchObject, LookupInsertRequest, LookupUpdateRequest, LookupPatchRequest>,
      ILookupService<TEntity>
    where TEntity : LookupEntityBase, new()
{
    private const int CodeMaxLength = 50;
    private const int NameMaxLength = 100;
    private static readonly Regex CodePattern = new("^[A-Za-z][A-Za-z0-9]*$", RegexOptions.Compiled);

    protected LookupService(AquaFlowDbContext dbContext, IMapper mapper)
        : base(
            dbContext,
            mapper,
            Array.Empty<IValidator<LookupInsertRequest>>(),
            Array.Empty<IValidator<LookupUpdateRequest>>(),
            Array.Empty<IValidator<LookupPatchRequest>>())
    {
    }

    // True when any FK column pointing at this codebook currently holds the code.
    protected abstract Task<bool> IsInUseAsync(string code);

    protected override IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, LookupSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (!string.IsNullOrWhiteSpace(search.Code))
        {
            var code = search.Code.Trim();
            query = query.Where(item => item.Code == code);
        }

        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            var name = search.Name.Trim();
            query = query.Where(item =>
                item.Name.Contains(name) ||
                (item.NameEn != null && item.NameEn.Contains(name)) ||
                (item.NameDe != null && item.NameDe.Contains(name)));
        }

        if (search.IsActive.HasValue)
        {
            var isActive = search.IsActive.Value;
            query = query.Where(item => item.IsActive == isActive);
        }

        return query;
    }

    // Default order is the codebook's own lifecycle order (SortOrder), then Name.
    protected override IQueryable<TEntity> ApplySorting(IQueryable<TEntity> query, LookupSearchObject? search)
    {
        if (string.IsNullOrWhiteSpace(search?.SortBy))
        {
            return query.OrderBy(item => item.SortOrder).ThenBy(item => item.Name);
        }

        return base.ApplySorting(query, search);
    }

    public override async Task<LookupResponse> InsertAsync(LookupInsertRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var code = NormalizeCode(request.Code);
        await EnsureUniqueCodeAsync(code);

        var entity = new TEntity
        {
            Code = code,
            Name = NormalizeName(request.Name),
            NameEn = NormalizeOptionalName(request.NameEn, nameof(request.NameEn)),
            NameDe = NormalizeOptionalName(request.NameDe, nameof(request.NameDe)),
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
            IsSystem = false,
            CreatedAt = DateTime.UtcNow
        };

        DbSet.Add(entity);
        await DbContext.SaveChangesAsync();

        return Mapper.Map<LookupResponse>(entity);
    }

    public override async Task<LookupResponse> UpdateAsync(int id, LookupUpdateRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var entity = await FindAsync(id);
        var newCode = await ValidateCodeChangeAsync(entity, request.Code);
        EnsureCanSetActive(entity, request.IsActive);

        entity.Name = NormalizeName(request.Name);
        entity.NameEn = NormalizeOptionalName(request.NameEn, nameof(request.NameEn));
        entity.NameDe = NormalizeOptionalName(request.NameDe, nameof(request.NameDe));
        entity.SortOrder = request.SortOrder;
        entity.IsActive = request.IsActive;

        return await SaveAsync(entity, newCode);
    }

    public override async Task<LookupResponse> PatchAsync(int id, LookupPatchRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var entity = await FindAsync(id);
        var newCode = request.Code == null ? null : await ValidateCodeChangeAsync(entity, request.Code);
        if (request.IsActive.HasValue)
        {
            EnsureCanSetActive(entity, request.IsActive.Value);
            entity.IsActive = request.IsActive.Value;
        }

        if (request.Name != null)
        {
            entity.Name = NormalizeName(request.Name);
        }

        if (request.NameEn != null)
        {
            entity.NameEn = NormalizeOptionalName(request.NameEn, nameof(request.NameEn));
        }

        if (request.NameDe != null)
        {
            entity.NameDe = NormalizeOptionalName(request.NameDe, nameof(request.NameDe));
        }

        if (request.SortOrder.HasValue)
        {
            entity.SortOrder = request.SortOrder.Value;
        }

        return await SaveAsync(entity, newCode);
    }

    public override async Task DeleteAsync(int id)
    {
        var entity = await FindAsync(id);

        if (entity.IsSystem)
        {
            throw new ClientException("Sistemska vrijednost se ne može obrisati.");
        }

        if (await IsInUseAsync(entity.Code))
        {
            throw new ClientException("Vrijednost se koristi i ne može se obrisati.");
        }

        DbSet.Remove(entity);
        await DbContext.SaveChangesAsync();
    }

    private async Task<TEntity> FindAsync(int id)
    {
        return await DbSet.FirstOrDefaultAsync(item => item.Id == id)
            ?? throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
    }

    // Returns the new code when it actually changes, otherwise null.
    private async Task<string?> ValidateCodeChangeAsync(TEntity entity, string? requestedCode)
    {
        var code = NormalizeCode(requestedCode);
        if (string.Equals(code, entity.Code, StringComparison.Ordinal))
        {
            return null;
        }

        if (entity.IsSystem)
        {
            throw new ClientException("Šifra sistemske vrijednosti se ne može mijenjati.");
        }

        await EnsureUniqueCodeAsync(code, entity.Id);

        // The FKs have no ON UPDATE CASCADE, so a code that is in use cannot be renamed.
        if (await IsInUseAsync(entity.Code))
        {
            throw new ClientException("Vrijednost se koristi i njena šifra se ne može mijenjati.");
        }

        return code;
    }

    private async Task<LookupResponse> SaveAsync(TEntity entity, string? newCode)
    {
        entity.UpdatedAt = DateTime.UtcNow;

        if (newCode == null)
        {
            await DbContext.SaveChangesAsync();
            return Mapper.Map<LookupResponse>(entity);
        }

        // Code is the FK principal (alternate) key, which EF Core will not modify on a tracked
        // entity, so the rename goes through a set-based UPDATE in the same transaction.
        await using var transaction = await DbContext.Database.BeginTransactionAsync();
        await DbContext.SaveChangesAsync();
        await DbSet
            .Where(item => item.Id == entity.Id)
            .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.Code, newCode));
        await transaction.CommitAsync();

        DbContext.Entry(entity).State = EntityState.Detached;
        return await GetByIdAsync(entity.Id);
    }

    private static void EnsureCanSetActive(TEntity entity, bool isActive)
    {
        if (entity.IsSystem && !isActive)
        {
            throw new ClientException("Sistemska vrijednost se ne može deaktivirati.");
        }
    }

    private async Task EnsureUniqueCodeAsync(string code, int? excludedId = null)
    {
        var normalized = code.ToLower();
        if (await DbSet.AnyAsync(item => item.Id != excludedId && item.Code.ToLower() == normalized))
        {
            throw new ClientException($"Šifra '{code}' već postoji.");
        }
    }

    private static string NormalizeCode(string? code)
    {
        var trimmed = code?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            throw new ClientException("Šifra je obavezna.");
        }

        if (trimmed.Length > CodeMaxLength)
        {
            throw new ClientException($"Šifra može imati najviše {CodeMaxLength} znakova.");
        }

        if (!CodePattern.IsMatch(trimmed))
        {
            throw new ClientException("Šifra mora počinjati slovom i sadržavati samo slova i cifre.");
        }

        return trimmed;
    }

    private static string NormalizeName(string? name)
    {
        var trimmed = name?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            throw new ClientException("Naziv je obavezan.");
        }

        if (trimmed.Length > NameMaxLength)
        {
            throw new ClientException($"Naziv može imati najviše {NameMaxLength} znakova.");
        }

        return trimmed;
    }

    private static string? NormalizeOptionalName(string? name, string field)
    {
        var trimmed = name?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            return null;
        }

        if (trimmed.Length > NameMaxLength)
        {
            throw new ClientException($"{field} može imati najviše {NameMaxLength} znakova.");
        }

        return trimmed;
    }
}
