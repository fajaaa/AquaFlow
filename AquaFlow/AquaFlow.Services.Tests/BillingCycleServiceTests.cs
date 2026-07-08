using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class BillingCycleServiceTests
{
    [Fact]
    public async Task InsertAsync_OpenCycleWhenAnotherIsAlreadyOpen_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new BillingCycleInsertRequest
        {
            Name = "Avgust 2026",
            PeriodFrom = new DateTime(2026, 8, 1),
            PeriodTo = new DateTime(2026, 8, 31),
            Status = "Open"
        }));
    }

    [Fact]
    public async Task InsertAsync_ClosedCycleWhenAnotherIsAlreadyOpen_Succeeds()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.InsertAsync(new BillingCycleInsertRequest
        {
            Name = "Avgust 2026",
            PeriodFrom = new DateTime(2026, 8, 1),
            PeriodTo = new DateTime(2026, 8, 31),
            Status = "Closed"
        });

        Assert.Equal("Closed", response.Status);
    }

    [Fact]
    public async Task InsertAsync_InvalidStatus_ThrowsValidationException()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<FluentValidation.ValidationException>(() => service.InsertAsync(new BillingCycleInsertRequest
        {
            Name = "Avgust 2026",
            PeriodFrom = new DateTime(2026, 8, 1),
            PeriodTo = new DateTime(2026, 8, 31),
            Status = "Bogus"
        }));
    }

    [Fact]
    public async Task UpdateAsync_ClosingOpenCycle_StampsClosedAt()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.UpdateAsync(1, new BillingCycleUpdateRequest
        {
            Name = "Juli 2026",
            PeriodFrom = new DateTime(2026, 7, 1),
            PeriodTo = new DateTime(2026, 7, 31),
            Status = "Closed"
        });

        Assert.Equal("Closed", response.Status);
        Assert.NotNull(response.ClosedAt);
    }

    [Fact]
    public async Task UpdateAsync_ReopeningClosedCycleWhileAnotherIsOpen_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        context.BillingCycles.Add(new BillingCycle { Id = 2, Name = "Juni 2026", PeriodFrom = new DateTime(2026, 6, 1), PeriodTo = new DateTime(2026, 6, 30), Status = "Closed", ClosedAt = new DateTime(2026, 7, 1) });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(2, new BillingCycleUpdateRequest
        {
            Name = "Juni 2026",
            PeriodFrom = new DateTime(2026, 6, 1),
            PeriodTo = new DateTime(2026, 6, 30),
            Status = "Open"
        }));
    }

    [Fact]
    public async Task PatchAsync_ReopeningCycle_ClearsClosedAt()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juni 2026", PeriodFrom = new DateTime(2026, 6, 1), PeriodTo = new DateTime(2026, 6, 30), Status = "Closed", ClosedAt = new DateTime(2026, 7, 1) });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.PatchAsync(1, new BillingCyclePatchRequest { Status = "Open" });

        Assert.Equal("Open", response.Status);
        Assert.Null(response.ClosedAt);
    }

    [Fact]
    public async Task PatchAsync_PeriodToBeforeExistingPeriodFrom_ThrowsClientException()
    {
        await using var context = CreateContext();
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Juli 2026", PeriodFrom = new DateTime(2026, 7, 1), PeriodTo = new DateTime(2026, 7, 31), Status = "Open" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(1, new BillingCyclePatchRequest
        {
            PeriodTo = new DateTime(2026, 6, 15)
        }));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static BillingCycleService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<BillingCyclePatchRequest, BillingCycle>()
            .IgnoreNullValues(true);

        IMapper mapper = new Mapper(mapperConfig);

        return new BillingCycleService(
            context,
            mapper,
            new IValidator<BillingCycleInsertRequest>[] { new BillingCycleInsertValidator() },
            new IValidator<BillingCycleUpdateRequest>[] { new BillingCycleUpdateValidator() },
            new IValidator<BillingCyclePatchRequest>[] { new BillingCyclePatchValidator() });
    }
}
