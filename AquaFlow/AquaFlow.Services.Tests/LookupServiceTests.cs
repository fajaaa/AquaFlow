using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Sqlite;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

// Codebook rules (LookupService) on InMemory, plus one SQLite test proving the FK-by-code is real.
public class LookupServiceTests
{
    [Fact]
    public async Task DeleteAsync_SystemRow_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(1));
        Assert.True(await context.PaymentMethods.AnyAsync(x => x.Id == 1));
    }

    [Fact]
    public async Task UpdateAsync_SystemRowCodeChange_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(1, new LookupUpdateRequest
        {
            Code = "ManualEntry",
            Name = "Ručno",
            IsActive = true
        }));
    }

    [Fact]
    public async Task PatchAsync_DeactivateSystemRow_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(1, new LookupPatchRequest { IsActive = false }));
    }

    [Fact]
    public async Task UpdateAsync_SystemRowNameChange_Succeeds()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        var result = await service.UpdateAsync(1, new LookupUpdateRequest
        {
            Code = PaymentMethod.Manual,
            Name = "Ručni unos",
            NameEn = "Manual entry",
            SortOrder = 5,
            IsActive = true
        });

        Assert.Equal(PaymentMethod.Manual, result.Code);
        Assert.Equal("Ručni unos", result.Name);
        Assert.True(result.IsSystem);
    }

    [Fact]
    public async Task InsertAsync_DuplicateCode_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new LookupInsertRequest
        {
            Code = "manual",
            Name = "Duplikat"
        }));
    }

    [Fact]
    public async Task InsertAsync_InvalidCode_ThrowsClientException()
    {
        await using var context = CreateContext();
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await Assert.ThrowsAsync<ClientException>(() => service.InsertAsync(new LookupInsertRequest
        {
            Code = "1 bad-code",
            Name = "Neispravno"
        }));
    }

    [Fact]
    public async Task InsertAsync_CreatesNonSystemRow()
    {
        await using var context = CreateContext();
        var service = new PaymentMethodLookupService(context, CreateMapper());

        var result = await service.InsertAsync(new LookupInsertRequest
        {
            Code = "Voucher",
            Name = "Vaučer",
            NameEn = "Voucher",
            NameDe = "Gutschein",
            SortOrder = 60
        });

        Assert.False(result.IsSystem);
        Assert.True(result.IsActive);
        Assert.Equal("Voucher", result.Code);
    }

    [Fact]
    public async Task DeleteAsync_NonSystemUnusedRow_Deletes()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        var service = new PaymentMethodLookupService(context, CreateMapper());

        await service.DeleteAsync(2);

        Assert.False(await context.PaymentMethods.AnyAsync(x => x.Id == 2));
    }

    [Fact]
    public async Task DeleteAsync_NonSystemRowInUse_ThrowsClientException()
    {
        await using var context = CreateContext();
        SeedPaymentMethods(context);
        context.Payments.Add(new Payment
        {
            Id = 1,
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 10m,
            PaymentMethod = "BankTransfer",
            Status = PaymentStatus.Completed,
            Provider = PaymentProvider.Manual
        });
        await context.SaveChangesAsync();
        var service = new PaymentMethodLookupService(context, CreateMapper());

        var exception = await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(2));
        Assert.Equal("Vrijednost se koristi i ne može se obrisati.", exception.Message);
        Assert.True(await context.PaymentMethods.AnyAsync(x => x.Id == 2));
    }

    [Fact]
    public async Task Sqlite_InvoiceWithUnknownStatus_ViolatesForeignKey()
    {
        using var database = new SqliteTestDatabase();

        await using (var context = database.CreateContext())
        {
            context.Invoices.Add(NewInvoiceLike(await context.Invoices.AsNoTracking().FirstAsync(), "INV-LOOKUP-1", "Bogus"));
            await Assert.ThrowsAsync<DbUpdateException>(() => context.SaveChangesAsync());
        }

        // Control: the same row with a codebook status is accepted, so the failure above is the FK.
        await using (var context = database.CreateContext())
        {
            context.Invoices.Add(NewInvoiceLike(await context.Invoices.AsNoTracking().FirstAsync(), "INV-LOOKUP-2", InvoiceStatus.Issued));
            await context.SaveChangesAsync();
        }
    }

    private static Invoice NewInvoiceLike(Invoice template, string invoiceNumber, string status) => new()
    {
        InvoiceNumber = invoiceNumber,
        CustomerId = template.CustomerId,
        WaterMeterId = template.WaterMeterId,
        BillingPeriodFrom = template.BillingPeriodFrom,
        BillingPeriodTo = template.BillingPeriodTo,
        PreviousReading = 0,
        CurrentReading = 10,
        ConsumptionM3 = 10,
        Subtotal = 10m,
        TotalAmount = 10m,
        Status = status,
        CreatedById = template.CreatedById
    };

    // Id 1 = system "Manual", Id 2 = non-system "BankTransfer".
    private static void SeedPaymentMethods(AquaFlowDbContext context)
    {
        context.PaymentMethods.AddRange(
            new PaymentMethodLookup { Id = 1, Code = PaymentMethod.Manual, Name = "Ručno evidentirano", SortOrder = 10, IsSystem = true },
            new PaymentMethodLookup { Id = 2, Code = "BankTransfer", Name = "Bankovni transfer", SortOrder = 40, IsSystem = false });
        context.SaveChanges();
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }

    private static IMapper CreateMapper() => new Mapper(new TypeAdapterConfig());
}
