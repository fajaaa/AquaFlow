using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.MeterReadings;

public class MeterReadingServiceTests
{
    [Fact]
    public async Task CreateForCollectorAsync_ValidRequest_CreatesReadingAndUpdatesLastReading()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1,
            Note = "Redovno ocitanje."
        });

        Assert.Equal(1, response.CollectorId);
        Assert.Equal(1, response.WaterMeterId);
        Assert.Equal(1, response.BillingCycleId);
        Assert.Equal(1, response.TariffId);
        Assert.Equal(100m, response.PreviousReadingValue);
        Assert.Equal(20m, response.ConsumptionM3);
        Assert.Equal("Collector", response.Source);

        var meter = await context.WaterMeters.SingleAsync(m => m.Id == 1);
        Assert.Equal(120m, meter.LastReading);

        var reading = await context.MeterReadings.SingleAsync(r => r.WaterMeterId == 1);
        Assert.Equal(1, reading.TariffId);

        var invoice = await context.Invoices.SingleAsync(i => i.Id == response.InvoiceId);
        Assert.Equal("INV-" + DateTime.UtcNow.Year + "-0001", invoice.InvoiceNumber);
        Assert.Equal(response.InvoiceNumber, invoice.InvoiceNumber);
        Assert.Equal(1, invoice.CustomerId);
        Assert.Equal(1, invoice.WaterMeterId);
        Assert.Equal(1, invoice.BillingCycleId);
        Assert.Equal(30m, invoice.Subtotal); // 20 m3 * 1.5
        Assert.Equal(0m, invoice.Tax);
        Assert.Equal(30m, invoice.TotalAmount);
        Assert.Equal(response.InvoiceTotalAmount, invoice.TotalAmount);
        Assert.Equal("Draft", invoice.Status);

        var invoiceItem = await context.InvoiceItems.SingleAsync(item => item.InvoiceId == invoice.Id);
        Assert.Equal(1, invoiceItem.TariffId);
        Assert.Equal(20m, invoiceItem.Quantity);
        Assert.Equal(1.5m, invoiceItem.UnitPrice);
        Assert.Equal(30m, invoiceItem.Amount);
    }

    [Fact]
    public async Task CreateForCollectorAsync_SecondInvoiceSameYear_IncrementsInvoiceNumber()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m, id: 1, settlementId: 1);
        SeedWaterMeter(context, lastReading: 50m, id: 2, settlementId: 1);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var first = await service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 120m,
            TariffId = 1
        });
        var second = await service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 2,
            ReadingValue = 60m,
            TariffId = 1
        });

        Assert.Equal($"INV-{DateTime.UtcNow.Year}-0001", first.InvoiceNumber);
        Assert.Equal($"INV-{DateTime.UtcNow.Year}-0002", second.InvoiceNumber);
    }

    [Fact]
    public async Task CreateForCollectorAsync_InactiveTariff_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m, isActive: false);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 120m,
                TariffId = 1
            }));

        Assert.Contains("not active", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_UnknownTariff_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 120m,
                TariffId = 999
            }));

        Assert.Contains("not found or is not active", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_DuplicateForSameBillingCycle_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        context.MeterReadings.Add(new MeterReading
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            BillingCycleId = 1,
            ReadingValue = 100m,
            PreviousReadingValue = 80m,
            ConsumptionM3 = 20m,
            ReadingDate = DateTime.UtcNow,
            Source = "Collector"
        });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 130m,
                BillingCycleId = 1,
                TariffId = 1
            }));

        Assert.Contains("already been recorded", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_NoOpenBillingCycle_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        context.BillingCycles.Add(new BillingCycle { Id = 1, Name = "Closed cycle", Status = "Closed" });
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 120m,
                TariffId = 1
            }));

        Assert.Contains("no open billing cycle", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_MultipleOpenBillingCycles_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedOpenBillingCycle(context, id: 2);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 120m,
                TariffId = 1
            }));

        Assert.Contains("Multiple open billing cycles", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_ReadingValueLowerThanLastReading_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 90m,
                TariffId = 1
            }));

        Assert.Contains("lower than the last recorded reading", exception.Message);
    }

    [Fact]
    public async Task CreateForCollectorAsync_ReadingValueLowerThanLastReadingWithNote_IsAllowed()
    {
        await using var context = CreateContext();
        SeedCollector(context);
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 2, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 90m,
            TariffId = 1,
            Note = "Vodomjer zamijenjen novim uredjajem."
        });

        Assert.Equal(90m, response.ReadingValue);
        Assert.Equal(100m, response.PreviousReadingValue);
        Assert.Equal(-10m, response.ConsumptionM3);
    }

    [Fact]
    public async Task CreateForCollectorAsync_NoCollectorProfile_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, lastReading: 100m);
        SeedOpenBillingCycle(context, id: 1);
        SeedTariff(context, id: 1, pricePerM3: 1.5m);
        await context.SaveChangesAsync();
        var service = CreateService(context);

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 999, new MeterReadingCollectorEntryRequest
            {
                WaterMeterId = 1,
                ReadingValue = 120m,
                TariffId = 1
            }));

        Assert.Contains("no collector profile", exception.Message);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedCollector(AquaFlowDbContext context)
    {
        context.UserRoles.Add(new UserRole { Id = 2, Name = "Collector" });
        context.Users.Add(new User
        {
            Id = 2,
            Email = "collector@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = 2,
            IsActive = true
        });
        context.CollectorProfiles.Add(new CollectorProfile { Id = 1, UserId = 2, EmployeeCode = "COL-0001" });
    }

    private static void SeedWaterMeter(AquaFlowDbContext context, decimal lastReading, int id = 1, int settlementId = 1)
    {
        if (!context.Settlements.Local.Any(s => s.Id == settlementId))
        {
            context.Settlements.Add(new Settlement { Id = settlementId, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });
        }
        context.WaterMeters.Add(new WaterMeter
        {
            Id = id,
            SerialNumber = $"WM-2026-{id:D4}",
            CustomerId = 1,
            SettlementId = settlementId,
            Status = "Active",
            InitialReading = 0,
            LastReading = lastReading
        });
    }

    private static void SeedOpenBillingCycle(AquaFlowDbContext context, int id)
    {
        context.BillingCycles.Add(new BillingCycle
        {
            Id = id,
            Name = $"Cycle {id}",
            PeriodFrom = DateTime.UtcNow,
            PeriodTo = DateTime.UtcNow.AddMonths(1),
            Status = "Open"
        });
    }

    private static void SeedTariff(AquaFlowDbContext context, int id, decimal pricePerM3, bool isActive = true)
    {
        context.Tariffs.Add(new Tariff
        {
            Id = id,
            Name = $"Tarifa {id}",
            Description = "Test tarifa",
            PricePerM3 = pricePerM3,
            IsActive = isActive
        });
    }

    private static MeterReadingService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        IMapper mapper = new Mapper(mapperConfig);

        return new MeterReadingService(
            context,
            mapper,
            new IValidator<MeterReadingInsertRequest>[] { new MeterReadingInsertValidator() },
            new IValidator<MeterReadingUpdateRequest>[] { new MeterReadingUpdateValidator() },
            new IValidator<MeterReadingPatchRequest>[] { new MeterReadingPatchValidator() },
            new IValidator<MeterReadingCollectorEntryRequest>[] { new MeterReadingCollectorEntryValidator() });
    }
}
