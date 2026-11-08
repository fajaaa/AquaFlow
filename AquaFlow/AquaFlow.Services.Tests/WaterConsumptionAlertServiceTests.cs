using System.Data.Common;
using AquaFlow.Model;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Forecasting;
using AquaFlow.Services.Tests.Notifications;
using AquaFlow.Services.Tests.Sqlite;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace AquaFlow.Services.Tests;

public class WaterConsumptionAlertServiceTests
{
    [Fact]
    public async Task RecomputeAsync_LastReadingIsAnOutlierSpike_CreatesAlert()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        // Stable low consumption, then one wildly-out-of-range last reading - the spike detector
        // should flag the last point as anomalous.
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        var created = await service.RecomputeAsync();

        var alert = Assert.Single(created);
        Assert.Equal("UnusualConsumptionSpike", alert.AlertType);
        Assert.Equal(90, alert.MeasuredValue);
        Assert.False(alert.IsResolved);
        Assert.Equal(1, alert.WaterMeterId);
        // Usual consumption = the 3 readings BEFORE the spike (20, 22, 21), never the spike itself.
        Assert.Equal(21m, alert.ThresholdValue);
        Assert.Single(await context.WaterConsumptionAlerts.ToListAsync());
    }

    // Professor's bug: the baseline used to be the average of the last 3 readings INCLUDING the anomaly
    // ((10 + 10 + 60) / 3 = 26.67). It must only use the readings before it.
    [Fact]
    public async Task RecomputeAsync_SpikeAfterStableSeries_ThresholdExcludesTheAnomalousReading()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 10, 10, 10, 10, 10, 10, 60 });
        var service = CreateService(context);

        var alert = Assert.Single(await service.RecomputeAsync());

        Assert.Equal(60m, alert.MeasuredValue);
        Assert.Equal(10m, alert.ThresholdValue);
        Assert.NotEqual(26.67m, alert.ThresholdValue);
        // 6 readings precede the spike, enough for the model's expectation for the measured reading.
        Assert.NotNull(alert.ExpectedValue);
        Assert.InRange(alert.ExpectedValue!.Value, 5m, 15m);
        Assert.True(alert.ExpectedUpperBound < alert.MeasuredValue);
    }

    [Fact]
    public async Task RecomputeAsync_CreatedAlert_MessageExplainsMeasuredExpectedIntervalAndBaseline()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 20, 21, 22, 20, 21, 90 });
        var service = CreateService(context);

        var alert = Assert.Single(await service.RecomputeAsync());

        Assert.NotNull(alert.ExpectedValue);
        var expected = new WaterConsumptionAlertService.AlertExplanation(
            "WM-1", 90m, alert.ExpectedValue, alert.ExpectedLowerBound, alert.ExpectedUpperBound, 21m, 3);
        Assert.True(expected.IsAbove);
        Assert.Equal(expected.BuildMessage(), alert.Message);
        Assert.Contains($"{90m:0.##} m³ za mjerač WM-1 znatno je iznad očekivane", alert.Message);
        Assert.Contains($"očekivao {alert.ExpectedValue:0.##} m³ (95% interval {alert.ExpectedLowerBound:0.##}–{alert.ExpectedUpperBound:0.##} m³)", alert.Message);
        Assert.Contains($"prosjek prethodna 3 očitanja je {21m:0.##} m³", alert.Message);
        Assert.Equal(21m, alert.ThresholdValue);
    }

    // Without a model expectation the reading is compared with the previous-readings average, so the
    // text must not claim an "expected" value that does not exist.
    [Fact]
    public void AlertExplanation_WithoutModelExpectation_KeepsOnlyBaselinePart()
    {
        var explanation = new WaterConsumptionAlertService.AlertExplanation("WM-7", 3m, null, null, null, 20m, 3);

        var message = explanation.BuildMessage();

        Assert.StartsWith($"Očitana potrošnja od {3m:0.##} m³ za mjerač WM-7 znatno je ispod uobičajene.", message);
        Assert.DoesNotContain("očekiv", message);
        Assert.DoesNotContain("Model", message);
        Assert.Contains($"Prosjek prethodna 3 očitanja je {20m:0.##} m³.", message);
    }

    [Fact]
    public void AlertExplanation_WithModelExpectation_SaysExpectedAndShowsInterval()
    {
        var explanation = new WaterConsumptionAlertService.AlertExplanation("WM-7", 30m, 20.5m, 18m, 23m, 21m, 3);

        var message = explanation.BuildMessage();

        Assert.StartsWith($"Očitana potrošnja od {30m:0.##} m³ za mjerač WM-7 znatno je iznad očekivane.", message);
        Assert.DoesNotContain("uobičajene", message);
        Assert.Contains($"Model je na osnovu prethodnih očitanja očekivao {20.5m:0.##} m³ (95% interval {18m:0.##}–{23m:0.##} m³);", message);
        Assert.Contains($"prosjek prethodna 3 očitanja je {21m:0.##} m³.", message);
    }

    // The push/inbox text and the full alert text use the same reference word.
    [Theory]
    [InlineData(true, "očekivane")]
    [InlineData(false, "uobičajene")]
    public void AlertExplanation_ShortAndFullMessage_UseSameReferenceWord(bool withExpected, string reference)
    {
        var explanation = withExpected
            ? new WaterConsumptionAlertService.AlertExplanation("WM-7", 30m, 20.5m, 18m, 23m, 21m, 3)
            : new WaterConsumptionAlertService.AlertExplanation("WM-7", 30m, null, null, null, 21m, 3);

        Assert.Contains($"znatno je iznad {reference}", explanation.BuildMessage());
        Assert.Contains($"znatno je iznad {reference}", explanation.BuildShortMessage());
    }

    // The HasData seed (seven hourly readings per meter, see AquaFlowDbContextSeed) demos a
    // model-explained alert: six readings precede the latest one, so the SSA expectation exists.
    // Meters 4 (10.0 after 11.8-15.4) and 6 (9.6 after 10.6-14.8) end on a clear drop and are flagged;
    // the other four end on an ordinary reading and are not.
    [Fact]
    public async Task RecomputeAsync_HasDataSeed_FlagsDroppingMetersWithModelExpectation()
    {
        using var database = new SqliteTestDatabase();
        await using var context = database.CreateContext();
        var service = CreateService(context);

        var created = await service.RecomputeAsync();

        Assert.Equal(new[] { 4, 6 }, created.Select(alert => alert.WaterMeterId).OrderBy(id => id));
        Assert.All(created, alert =>
        {
            Assert.NotNull(alert.ExpectedValue);
            Assert.NotNull(alert.ExpectedLowerBound);
            Assert.NotNull(alert.ExpectedUpperBound);
            Assert.True(alert.MeasuredValue < alert.ExpectedLowerBound,
                $"Meter {alert.WaterMeterId}: {alert.MeasuredValue} not below {alert.ExpectedLowerBound}.");
            Assert.Contains("znatno je ispod očekivane.", alert.Message);
            Assert.Contains($"očekivao {alert.ExpectedValue:0.##} m³ (95% interval {alert.ExpectedLowerBound:0.##}–{alert.ExpectedUpperBound:0.##} m³)", alert.Message);
        });
    }

    [Fact]
    public async Task RecomputeAsync_CreatedAlert_StagesWarningNotificationForTheCustomer()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        await service.RecomputeAsync(waterMeterId: 1, actorUserId: 3);

        var notification = Assert.Single(await context.Notifications.Include(n => n.UserNotifications).ToListAsync());
        Assert.Equal(RelatedEntityTypes.WaterMeter, notification.RelatedEntityType);
        Assert.Equal(1, notification.RelatedEntityId);
        Assert.Equal(NotificationType.Warning, notification.Type);
        Assert.Equal("Neuobičajena potrošnja vode", notification.Title);
        Assert.EndsWith(" Pogledajte preporuke u aplikaciji.", notification.Body);
        Assert.Equal(3, notification.CreatedById);
        Assert.Equal(1, Assert.Single(notification.UserNotifications).UserId);
    }

    // No human actor (e.g. a background run): attributed to the customer, who is still notified.
    [Fact]
    public async Task RecomputeAsync_NoActor_NotificationAttributedToAndDeliveredToCustomer()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        await service.RecomputeAsync();

        var notification = Assert.Single(await context.Notifications.Include(n => n.UserNotifications).ToListAsync());
        Assert.Equal(1, notification.CreatedById);
        Assert.Equal(1, Assert.Single(notification.UserNotifications).UserId);
    }

    [Fact]
    public async Task RecomputeAsync_NoAnomaly_CreatesNoAlertAndNoNotification()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 20, 21, 22, 20, 21 });
        var service = CreateService(context);

        Assert.Empty(await service.RecomputeAsync());
        Assert.Empty(await context.Notifications.ToListAsync());
    }

    [Fact]
    public async Task ResolveAsync_SetsIsResolvedAndResolvedAt()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);
        var alertId = Assert.Single(await service.RecomputeAsync()).Id;

        var resolved = await service.ResolveAsync(alertId);

        Assert.True(resolved.IsResolved);
        Assert.NotNull(resolved.ResolvedAt);
        var stored = await context.WaterConsumptionAlerts.AsNoTracking().SingleAsync();
        Assert.True(stored.IsResolved);
        Assert.NotNull(stored.ResolvedAt);
    }

    [Fact]
    public async Task ResolveAsync_AlreadyResolved_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);
        var alertId = Assert.Single(await service.RecomputeAsync()).Id;
        await service.ResolveAsync(alertId);

        var ex = await Assert.ThrowsAsync<AquaFlow.Model.Exceptions.ClientException>(() => service.ResolveAsync(alertId));

        Assert.Equal("Alarm je već riješen.", ex.Message);
    }

    [Fact]
    public async Task ResolveAsync_UnknownId_ThrowsKeyNotFound()
    {
        await using var context = CreateContext();

        await Assert.ThrowsAsync<KeyNotFoundException>(() => CreateService(context).ResolveAsync(999));
    }

    [Fact]
    public async Task ManualWrites_AreRejected()
    {
        await using var context = CreateContext();
        var service = CreateService(context);

        await Assert.ThrowsAsync<AquaFlow.Model.Exceptions.ClientException>(() => service.InsertAsync(new WaterConsumptionAlertInsertRequest()));
        await Assert.ThrowsAsync<AquaFlow.Model.Exceptions.ClientException>(() => service.UpdateAsync(1, new WaterConsumptionAlertUpdateRequest()));
        await Assert.ThrowsAsync<AquaFlow.Model.Exceptions.ClientException>(() => service.PatchAsync(1, new WaterConsumptionAlertPatchRequest()));
        await Assert.ThrowsAsync<AquaFlow.Model.Exceptions.ClientException>(() => service.DeleteAsync(1));
    }

    // The idempotency check only looks at UNRESOLVED alerts: once an admin resolves the alert, the next
    // recompute may raise a fresh one for the same meter.
    [Fact]
    public async Task RecomputeAsync_AfterResolve_CreatesNewAlertForSameMeter()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);
        var first = Assert.Single(await service.RecomputeAsync());
        Assert.Empty(await service.RecomputeAsync());

        await service.ResolveAsync(first.Id);
        var second = Assert.Single(await service.RecomputeAsync());

        Assert.NotEqual(first.Id, second.Id);
        Assert.Equal(2, await context.WaterConsumptionAlerts.CountAsync());
    }

    // N+1 guard: the number of SQL commands RecomputeAsync issues must not grow with the meter count.
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task RecomputeAsync_CommandCount_IsIndependentOfMeterCount(bool withAnomalies)
    {
        var (fewCommands, fewCreated) = await CountRecomputeCommandsAsync(meterCount: 2, withAnomalies);
        var (manyCommands, manyCreated) = await CountRecomputeCommandsAsync(meterCount: 10, withAnomalies);

        Assert.Equal(withAnomalies ? 1 : 0, fewCreated);
        Assert.Equal(fewCreated, manyCreated);
        // Meters, readings and open alerts are at least 3 queries - proves the counter is wired up.
        Assert.True(fewCommands >= 3, $"Only {fewCommands} commands counted.");
        Assert.Equal(fewCommands, manyCommands);
    }

    // Fresh SQLite database (real SQL, real commands). Seeded meters are deactivated so only the test's
    // meters are analyzed. Meter 0 is normal (or, with anomalies, spiking -> 1 new alert); meter 1 is
    // normal (or, with anomalies, spiking but already has an open alert -> skipped); the rest are normal.
    private static async Task<(int Commands, int Created)> CountRecomputeCommandsAsync(int meterCount, bool withAnomalies)
    {
        using var database = new SqliteTestDatabase();
        var normal = new decimal[] { 20, 21, 20, 22, 21, 20, 21, 22, 20, 21 };
        var spiking = normal.Append(90m).ToArray();

        await using (var seed = database.CreateContext())
        {
            await seed.WaterMeters.ExecuteUpdateAsync(setters => setters.SetProperty(meter => meter.Status, WaterMeterStatus.Inactive));
            var customerId = await seed.CustomerProfiles.Select(customer => customer.Id).FirstAsync();
            var settlementId = await seed.Settlements.Select(settlement => settlement.Id).FirstAsync();
            var collectorId = await seed.CollectorProfiles.Select(collector => collector.Id).FirstAsync();

            for (var i = 0; i < meterCount; i++)
            {
                var meter = new WaterMeter
                {
                    SerialNumber = $"NPLUS1-{i}",
                    CustomerId = customerId,
                    SettlementId = settlementId,
                    Status = WaterMeterStatus.Active
                };
                seed.WaterMeters.Add(meter);
                await seed.SaveChangesAsync();

                var series = withAnomalies && i < 2 ? spiking : normal;
                var date = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc);
                decimal previous = 0;
                foreach (var consumption in series)
                {
                    seed.MeterReadings.Add(new MeterReading
                    {
                        WaterMeterId = meter.Id,
                        CollectorId = collectorId,
                        PreviousReadingValue = previous,
                        ReadingValue = previous + consumption,
                        ConsumptionM3 = consumption,
                        ReadingDate = date
                    });
                    previous += consumption;
                    date = date.AddMonths(1);
                }

                if (withAnomalies && i == 1)
                {
                    seed.WaterConsumptionAlerts.Add(new WaterConsumptionAlert
                    {
                        CustomerId = customerId,
                        WaterMeterId = meter.Id,
                        AlertType = WaterConsumptionAlertService.UnusualConsumptionSpikeType,
                        Message = "open",
                        IsResolved = false
                    });
                }
            }
            await seed.SaveChangesAsync();
        }

        var counter = new CommandCounter();
        await using var context = database.CreateContext(counter);
        var service = CreateService(context);

        counter.Count = 0;
        var created = await service.RecomputeAsync(actorUserId: null);

        return (counter.Count, created.Count);
    }

    private sealed class CommandCounter : DbCommandInterceptor
    {
        public int Count { get; set; }

        public override InterceptionResult<DbDataReader> ReaderExecuting(DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result)
        {
            Count++;
            return base.ReaderExecuting(command, eventData, result);
        }

        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result, CancellationToken cancellationToken = default)
        {
            Count++;
            return base.ReaderExecutingAsync(command, eventData, result, cancellationToken);
        }

        public override InterceptionResult<int> NonQueryExecuting(DbCommand command, CommandEventData eventData, InterceptionResult<int> result)
        {
            Count++;
            return base.NonQueryExecuting(command, eventData, result);
        }

        public override ValueTask<InterceptionResult<int>> NonQueryExecutingAsync(DbCommand command, CommandEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
        {
            Count++;
            return base.NonQueryExecutingAsync(command, eventData, result, cancellationToken);
        }

        public override InterceptionResult<object> ScalarExecuting(DbCommand command, CommandEventData eventData, InterceptionResult<object> result)
        {
            Count++;
            return base.ScalarExecuting(command, eventData, result);
        }

        public override ValueTask<InterceptionResult<object>> ScalarExecutingAsync(DbCommand command, CommandEventData eventData, InterceptionResult<object> result, CancellationToken cancellationToken = default)
        {
            Count++;
            return base.ScalarExecutingAsync(command, eventData, result, cancellationToken);
        }
    }

    [Fact]
    public async Task RecomputeAsync_CalledAgainWhilePreviousAlertUnresolved_DoesNotCreateDuplicate()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 20, 21, 20, 22, 21, 90 });
        var service = CreateService(context);

        var firstRun = await service.RecomputeAsync();
        var secondRun = await service.RecomputeAsync();

        Assert.Single(firstRun);
        Assert.Empty(secondRun);
        Assert.Single(await context.WaterConsumptionAlerts.ToListAsync());
    }

    [Fact]
    public async Task RecomputeAsync_FewerThanFiveCountingReadings_SkipsMeterWithoutError()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        SeedReadings(context, waterMeterId: 1, consumption: new decimal[] { 10, 12, 11 });
        var service = CreateService(context);

        var created = await service.RecomputeAsync();

        Assert.Empty(created);
        Assert.Empty(await context.WaterConsumptionAlerts.ToListAsync());
    }

    [Fact]
    public async Task GetAllAsync_IsResolved_FiltersAlerts()
    {
        await using var context = CreateContext();
        SeedWaterMeter(context, waterMeterId: 1);
        context.WaterConsumptionAlerts.AddRange(
            new WaterConsumptionAlert { Id = 1, CustomerId = 1, WaterMeterId = 1, AlertType = "UnusualConsumptionSpike", Message = "open", IsResolved = false },
            new WaterConsumptionAlert { Id = 2, CustomerId = 1, WaterMeterId = 1, AlertType = "UnusualConsumptionSpike", Message = "done", IsResolved = true });
        context.SaveChanges();
        var service = CreateService(context);

        var open = await service.GetAllAsync(new WaterConsumptionAlertSearchObject { IsResolved = false });
        var resolved = await service.GetAllAsync(new WaterConsumptionAlertSearchObject { IsResolved = true });
        var all = await service.GetAllAsync(new WaterConsumptionAlertSearchObject());

        Assert.Equal(1, Assert.Single(open.Items).Id);
        Assert.Equal(2, Assert.Single(resolved.Items).Id);
        Assert.Equal(2, all.Items.Count);
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static void SeedWaterMeter(AquaFlowDbContext context, int waterMeterId)
    {
        context.Settlements.Add(new Settlement { Id = 1, Name = "Sarajevo", MunicipalityId = 1, PostalCode = "71000" });

        context.UserRoles.Add(new UserRole { Id = 1, Name = "Customer" });
        context.Users.Add(new User { Id = 1, Email = "amina@aquaflow.ba", PasswordHash = "hash", PasswordSalt = "salt", UserRoleId = 1, IsActive = true });

        context.CustomerProfiles.Add(new CustomerProfile { Id = 1, UserId = 1, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 });

        context.WaterMeters.Add(new WaterMeter
        {
            Id = waterMeterId,
            SerialNumber = $"WM-{waterMeterId}",
            CustomerId = 1,
            SettlementId = 1,
            Status = WaterMeterStatus.Active,
            InitialReading = 0,
            LastReading = 0
        });

        context.SaveChanges();
    }

    // Readings are seeded oldest-first, one day apart, with no invoice, so they are all "counting"
    // under MeterReadingService.CountingReadings (VoidedAt == null, InvoiceId == null).
    private static void SeedReadings(AquaFlowDbContext context, int waterMeterId, decimal[] consumption)
    {
        var readingDate = DateTime.UtcNow.AddDays(-consumption.Length);
        decimal previousReading = 0;

        for (var i = 0; i < consumption.Length; i++)
        {
            var readingValue = previousReading + consumption[i];
            context.MeterReadings.Add(new MeterReading
            {
                WaterMeterId = waterMeterId,
                CollectorId = 1,
                ReadingValue = readingValue,
                PreviousReadingValue = previousReading,
                ConsumptionM3 = consumption[i],
                ReadingDate = readingDate.AddDays(i),
            });
            previousReading = readingValue;
        }

        context.SaveChanges();
    }

    // Mirrors the flatten config from Program.cs so CustomerFirstName/CustomerLastName/
    // WaterMeterSerialNumber populate from the loaded navigations.
    private static WaterConsumptionAlertService CreateService(AquaFlowDbContext context)
    {
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<WaterConsumptionAlert, WaterConsumptionAlertResponse>()
            .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
            .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
            .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
        IMapper mapper = new Mapper(mapperConfig);

        return new WaterConsumptionAlertService(
            context,
            mapper,
            new IValidator<WaterConsumptionAlertInsertRequest>[] { new WaterConsumptionAlertInsertValidator() },
            Array.Empty<IValidator<WaterConsumptionAlertUpdateRequest>>(),
            Array.Empty<IValidator<WaterConsumptionAlertPatchRequest>>(),
            new ConsumptionForecastingService(context),
            TestSystemNotifications.Create(context));
    }
}
