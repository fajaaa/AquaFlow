using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Minimal admin path: an Admin opens/closes billing cycles through this API instead of editing SQL
// by hand (see the Meter Reading Flow section in AGENTS.md). GetAll/GetById stay ungated on the
// controller so any authenticated caller - including the collector reading-entry screen - can still
// look up the current Open cycle; only Create/Update/Patch/Delete require BillingCycles.Manage.
public class BillingCycleService
    : EfCrudService<BillingCycle, BillingCycleResponse, BillingCycleSearchObject, BillingCycleInsertRequest, BillingCycleUpdateRequest, BillingCyclePatchRequest>,
        IBillingCycleService
{
    private readonly AquaFlowDbContext _dbContext;

    public BillingCycleService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<BillingCycleInsertRequest>> insertValidators,
        IEnumerable<IValidator<BillingCycleUpdateRequest>> updateValidators,
        IEnumerable<IValidator<BillingCyclePatchRequest>> patchValidators)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
    }

    // Only one Open cycle is allowed system-wide - MeterReadingService.CreateForCollectorAsync
    // relies on that invariant to resolve the current period without an explicit BillingCycleId.
    protected override async Task BeforeInsertAsync(BillingCycleInsertRequest request)
    {
        if (request.Status == "Open")
        {
            await EnsureNoOtherOpenCycleAsync(excludedId: null);
        }
    }

    protected override async Task BeforeUpdateAsync(int id, BillingCycleUpdateRequest request, BillingCycle entity)
    {
        if (request.Status == "Open" && entity.Status != "Open")
        {
            await EnsureNoOtherOpenCycleAsync(id);
        }

        ApplyStatusTransition(entity, request.Status);
    }

    protected override async Task BeforePatchAsync(int id, BillingCyclePatchRequest request, BillingCycle entity)
    {
        if (request.Status == "Open" && entity.Status != "Open")
        {
            await EnsureNoOtherOpenCycleAsync(id);
        }

        if (request.PeriodFrom.HasValue || request.PeriodTo.HasValue)
        {
            var periodFrom = request.PeriodFrom ?? entity.PeriodFrom;
            var periodTo = request.PeriodTo ?? entity.PeriodTo;
            if (periodTo < periodFrom)
            {
                throw new ClientException("PeriodTo must not be earlier than PeriodFrom.");
            }
        }

        if (request.Status != null)
        {
            ApplyStatusTransition(entity, request.Status);
        }
    }

    // Closing a cycle stamps ClosedAt; reopening one clears it. Neither request DTO carries
    // ClosedAt, so mutating the tracked entity here survives the Mapster mapping that runs
    // right after BeforeUpdateAsync/BeforePatchAsync (see EfCrudService.UpdateAsync/PatchAsync).
    private static void ApplyStatusTransition(BillingCycle entity, string newStatus)
    {
        if (newStatus == "Closed" && entity.Status != "Closed")
        {
            entity.ClosedAt = DateTime.UtcNow;
        }
        else if (newStatus == "Open" && entity.Status != "Open")
        {
            entity.ClosedAt = null;
        }
    }

    private async Task EnsureNoOtherOpenCycleAsync(int? excludedId)
    {
        var alreadyOpen = await _dbContext.BillingCycles.AnyAsync(cycle =>
            cycle.Id != excludedId &&
            cycle.Status == "Open");

        if (alreadyOpen)
        {
            throw new ClientException("There is already an open billing cycle.");
        }
    }
}
