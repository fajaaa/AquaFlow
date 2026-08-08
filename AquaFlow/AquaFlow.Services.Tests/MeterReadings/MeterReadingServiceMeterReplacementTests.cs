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

// Covers the negative-consumption hole: a ReadingValue below the water meter's last recorded
// reading used to be let through by a bare Note, computing a negative ConsumptionM3 and pricing a
// negative-total Issued invoice that RecordPaymentInternalAsync (BaseInvoiceState.cs) can never
// mark Paid (it rejects amount <= 0). IsMeterReplacement is now the only way a lower reading is
// ever accepted, and a zero-consumption reading must not create an invoice either, for the same
// unpayable-invoice reason.
public class MeterReadingServiceMeterReplacementTests
{
    // Without IsMeterReplacement, a lower reading is ALWAYS rejected - a Note alone (the old bypass)
    // no longer has any effect.
    [Fact]
    public async Task CreateForCollectorAsync_LowerReadingWithoutReplacementFlag_ThrowsClientExceptionEvenWithNote()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var waterMeter = context.WaterMeters.First(m => m.Id == 1);
        waterMeter.LastReading = 1500m;
        context.SaveChanges();

        var service = CreateService(context);
        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 5,
            TariffId = 1,
            IsMeterReplacement = false,
            Note = "Vodomjer je fizički zamijenjen."
        };

        var exception = await Assert.ThrowsAsync<ClientException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));

        Assert.Contains("lower than the last recorded reading", exception.Message);
        Assert.Empty(context.MeterReadings);
        Assert.Empty(context.Invoices);
        Assert.Equal(1500m, waterMeter.LastReading);
    }

    // With IsMeterReplacement, the baseline is forced to 0 regardless of WaterMeter.LastReading, so
    // consumption equals the full ReadingValue, the invoice prices from that, and LastReading is
    // reset to the new (lower) value.
    [Fact]
    public async Task CreateForCollectorAsync_MeterReplacement_BaselinesAtZeroAndPricesInvoiceFromFullReadingValue()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var waterMeter = context.WaterMeters.First(m => m.Id == 1);
        waterMeter.LastReading = 1500m;
        context.SaveChanges();

        var service = CreateService(context);
        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 5,
            TariffId = 1,
            IsMeterReplacement = true,
            ReplacedMeterFinalReading = 1500m,
            Note = "Vodomjer je fizički zamijenjen."
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.Equal(0m, response.PreviousReadingValue);
        Assert.Equal(5m, response.ConsumptionM3);
        Assert.True(response.InvoiceId.HasValue);
        Assert.Equal(25m, response.InvoiceTotalAmount); // ReadingValue (5) * tariff PricePerM3 (5)

        Assert.Equal(5m, waterMeter.LastReading);

        var reading = await context.MeterReadings.FirstAsync(r => r.Id == response.Id);
        Assert.Equal(1500m, reading.ReplacedMeterFinalReading);
    }

    // A freshly replaced meter can legitimately be re-read at 0 (no consumption yet). Consumption
    // is still computed against the forced 0 baseline, LastReading is still reset, but - same as
    // any other zero-consumption reading - no invoice is created.
    [Fact]
    public async Task CreateForCollectorAsync_MeterReplacementWithZeroReadingValue_RecordsReadingWithNoInvoice()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var waterMeter = context.WaterMeters.First(m => m.Id == 1);
        waterMeter.LastReading = 1500m;
        context.SaveChanges();

        var service = CreateService(context);
        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 0,
            TariffId = 1,
            IsMeterReplacement = true,
            Note = "Novi vodomjer postavljen, još nema potrošnje."
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.Equal(0m, response.PreviousReadingValue);
        Assert.Equal(0m, response.ConsumptionM3);
        Assert.Null(response.InvoiceId);
        Assert.Null(response.InvoiceNumber);
        Assert.Null(response.InvoiceTotalAmount);
        Assert.Equal(0m, waterMeter.LastReading);
        Assert.Empty(context.Invoices);
    }

    // Zero consumption on the ordinary (non-replacement) path must not create an invoice either: a
    // 0.00 KM Issued invoice is just as permanently stuck as a negative one.
    [Fact]
    public async Task CreateForCollectorAsync_ZeroConsumption_RecordsReadingWithNoInvoice()
    {
        await using var context = CreateContext();
        SeedTestData(context); // WaterMeter Id=1 seeds with LastReading = 0
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 0,
            TariffId = 1
        };

        var response = await service.CreateForCollectorAsync(callerUserId: 3, request);

        Assert.Null(response.InvoiceId);
        Assert.Null(response.InvoiceNumber);
        Assert.Null(response.InvoiceTotalAmount);
        Assert.Empty(context.Invoices);

        var reading = await context.MeterReadings.FirstAsync(r => r.Id == response.Id);
        Assert.Null(reading.InvoiceId);
    }

    // MeterReadingCollectorEntryValidator: Note is required when IsMeterReplacement is set.
    [Fact]
    public async Task CreateForCollectorAsync_MeterReplacementWithoutNote_ThrowsValidationException()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 5,
            TariffId = 1,
            IsMeterReplacement = true,
            Note = null
        };

        await Assert.ThrowsAsync<ValidationException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));
    }

    // MeterReadingCollectorEntryValidator: ReplacedMeterFinalReading, when supplied, cannot be negative.
    [Fact]
    public async Task CreateForCollectorAsync_NegativeReplacedMeterFinalReading_ThrowsValidationException()
    {
        await using var context = CreateContext();
        SeedTestData(context);
        var service = CreateService(context);

        var request = new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 5,
            TariffId = 1,
            IsMeterReplacement = true,
            Note = "Vodomjer je fizički zamijenjen.",
            ReplacedMeterFinalReading = -1m
        };

        await Assert.ThrowsAsync<ValidationException>(
            () => service.CreateForCollectorAsync(callerUserId: 3, request));
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedTestData(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.UserRoles.Add(new UserRole { Id = 2, Name = "Collector" });

        context.Users.Add(new User { Id = 1, Email = "customer@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 2, Email = "admin@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });
        context.Users.Add(new User { Id = 3, Email = "collector@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 2, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile
        {
            Id = 1,
            UserId = 1,
            FirstName = "Amina",
            LastName = "Amidzic",
            CustomerCode = "CUS-0001",
            SettlementId = 1
        });

        context.CollectorProfiles.Add(new CollectorProfile
        {
            Id = 1,
            UserId = 3,
            EmployeeCode = "EMP-0001"
        });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = 1,
            SerialNumber = "WM-1",
            CustomerId = 1,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0,
            LastReading = 0
        });

        context.Tariffs.Add(new Tariff
        {
            Id = 1,
            Name = "Standard",
            PricePerM3 = 5m,
            IsActive = true
        });

        context.SaveChanges();
    }

    private static MeterReadingService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<MeterReading, Model.Responses.MeterReadingResponse>();
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
