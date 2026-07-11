using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class FaultReportService
    : EfCrudService<FaultReport, FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>,
        IFaultReportService
{
    // Matches the exact values the FE status pills/admin advance-button switch on
    // (fault_report_status_pill.dart, admin_fault_reports_screen.dart's _nextStatus) -
    // there is no "Closed" status anywhere in the client, so it is deliberately not
    // included here. Ordinal (case-sensitive) since every caller today writes/reads
    // these exact PascalCase values (e.g. FaultReport.Status's "New" default,
    // FaultReportSearchObject's exact-equality filter).
    private const string ResolvedStatus = "Resolved";
    private static readonly HashSet<string> AllowedStatuses = new(StringComparer.Ordinal)
    {
        "New",
        "InProgress",
        ResolvedStatus
    };

    public FaultReportService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<FaultReportInsertRequest>> insertValidators,
        IEnumerable<IValidator<FaultReportUpdateRequest>> updateValidators,
        IEnumerable<IValidator<FaultReportPatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
    }

    protected override IQueryable<FaultReport> IncludeForRead(IQueryable<FaultReport> query) =>
        query.Include(f => f.Customer).Include(f => f.Settlement);

    // Guards the FK columns the insert validator only checks with GreaterThan(0) - an id that is
    // positive but doesn't exist would otherwise reach SaveChangesAsync and surface as a raw
    // DbUpdateException (500) instead of a clean 400. Covers both the self-service and the
    // admin (manage) insert path, since both go through InsertAsync.
    protected override async Task BeforeInsertAsync(FaultReportInsertRequest request)
    {
        await EnsureSettlementExistsAsync(request.SettlementId);

        if (request.WaterMeterId.HasValue)
        {
            await EnsureWaterMeterExistsAsync(request.WaterMeterId.Value);
        }
    }

    private async Task EnsureSettlementExistsAsync(int settlementId)
    {
        if (!await DbContext.Settlements.AnyAsync(settlement => settlement.Id == settlementId))
        {
            throw new ClientException("Settlement not found.");
        }
    }

    private async Task EnsureWaterMeterExistsAsync(int waterMeterId)
    {
        if (!await DbContext.WaterMeters.AnyAsync(waterMeter => waterMeter.Id == waterMeterId))
        {
            throw new ClientException("Water meter not found.");
        }
    }

    // Enforces the allowed status set on PATCH (the only endpoint the FE ever uses to
    // change status - Insert always forces "New" server-side, Update/PUT is unused by
    // the FE) and keeps ResolvedAt in sync with Status server-side, since
    // FaultReportPatchRequest lets a caller set them independently otherwise:
    // - Status outside AllowedStatuses -> ClientException (400).
    // - Status moving to Resolved with no ResolvedAt in the request -> stamp UtcNow.
    // - Status moving to a non-terminal value with no ResolvedAt in the request -> clear it.
    // Both stamp/clear branches only apply when the request didn't already supply an
    // explicit ResolvedAt; an explicit value in the same request always wins, since the
    // patch mapper (Program.cs's IgnoreNullValues(true) config) skips null members, so a
    // non-null request.ResolvedAt overwrites whatever is set here right after.
    protected override Task BeforePatchAsync(int id, FaultReportPatchRequest request, FaultReport entity)
    {
        if (request.Status is not null)
        {
            if (!AllowedStatuses.Contains(request.Status))
            {
                throw new ClientException(
                    $"Status must be one of: {string.Join(", ", AllowedStatuses)}.");
            }

            if (request.ResolvedAt is null)
            {
                entity.ResolvedAt = request.Status == ResolvedStatus ? DateTime.UtcNow : null;
            }
        }

        return Task.CompletedTask;
    }

    public async Task<FaultReportOwnership?> GetOwnershipAsync(int id)
    {
        return await DbContext.FaultReports
            .Where(f => f.Id == id)
            .Select(f => new FaultReportOwnership(f.CustomerId, f.Status))
            .FirstOrDefaultAsync();
    }

    protected override async Task LoadReferencesAsync(FaultReport entity)
    {
        await DbContext.Entry(entity).Reference(f => f.Customer).LoadAsync();
        await DbContext.Entry(entity).Reference(f => f.Settlement).LoadAsync();
    }

    protected override IQueryable<FaultReport> ApplyFilters(IQueryable<FaultReport> query, FaultReportSearchObject? search)
    {
        if (search == null)
        {
            return query;
        }

        if (search.ReportedById.HasValue)
        {
            query = query.Where(f => f.ReportedById == search.ReportedById.Value);
        }

        if (search.WaterMeterId.HasValue)
        {
            query = query.Where(f => f.WaterMeterId == search.WaterMeterId.Value);
        }

        if (search.CustomerId.HasValue)
        {
            query = query.Where(f => f.CustomerId == search.CustomerId.Value);
        }

        if (search.SettlementId.HasValue)
        {
            query = query.Where(f => f.SettlementId == search.SettlementId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.Status))
        {
            query = query.Where(f => f.Status == search.Status);
        }

        if (!string.IsNullOrWhiteSpace(search.Term))
        {
            // Lowered explicitly rather than relying on the DB collation being case-insensitive, so
            // the match is guaranteed regardless of provider/collation - same precedent as
            // WaterMeterService.ApplyFilters.
            var term = search.Term.Trim().ToLower();
            query = query.Where(f =>
                f.Title.ToLower().Contains(term) ||
                (f.Customer != null && (
                    f.Customer.FirstName.ToLower().Contains(term) ||
                    f.Customer.LastName.ToLower().Contains(term) ||
                    (f.Customer.FirstName + " " + f.Customer.LastName).ToLower().Contains(term))) ||
                (f.Settlement != null && f.Settlement.Name.ToLower().Contains(term)));
        }

        return query;
    }
}
