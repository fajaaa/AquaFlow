using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

public class FaultReportPhotoServiceTests
{
    [Fact]
    public async Task UploadAsync_InsertsRowWithSizeBytesFromData()
    {
        await using var context = CreateContext();
        context.FaultReports.Add(new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);

        var response = await service.UploadAsync(1, new byte[] { 1, 2, 3, 4 }, "image/jpeg", "leak.jpg");

        var row = await context.FaultReportPhotos.SingleAsync();
        Assert.Equal(response.Id, row.Id);
        Assert.Equal(4, row.SizeBytes);
        Assert.Equal("leak.jpg", row.FileName);
        Assert.Equal("image/jpeg", row.ContentType);
        Assert.Equal(4, response.SizeBytes);
    }

    [Fact]
    public async Task GetMetadataAsync_OnlyReturnsRowsForTheGivenReport()
    {
        await using var context = CreateContext();
        context.FaultReports.AddRange(
            new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" },
            new FaultReport { Id = 2, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "No water" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");
        await service.UploadAsync(2, new byte[] { 1 }, "image/jpeg", "b.jpg");

        var result = await service.GetMetadataAsync(1);

        var item = Assert.Single(result);
        Assert.Equal("a.jpg", item.FileName);
    }

    [Fact]
    public async Task GetFileAsync_ReturnsRawBytesAndContentType()
    {
        await using var context = CreateContext();
        context.FaultReports.Add(new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/webp", "leak.webp");

        var file = await service.GetFileAsync(1, uploaded.Id);

        Assert.Equal(new byte[] { 9, 8, 7 }, file.Data);
        Assert.Equal("image/webp", file.ContentType);
        Assert.Equal("leak.webp", file.FileName);
    }

    [Fact]
    public async Task GetFileAsync_WrongFaultReportId_ThrowsKeyNotFoundException()
    {
        await using var context = CreateContext();
        context.FaultReports.AddRange(
            new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" },
            new FaultReport { Id = 2, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "No water" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.GetFileAsync(2, uploaded.Id));
    }

    [Fact]
    public async Task DeleteAsync_RemovesTheRow()
    {
        await using var context = CreateContext();
        context.FaultReports.Add(new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);
        var uploaded = await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        await service.DeleteAsync(1, uploaded.Id);

        Assert.Empty(await context.FaultReportPhotos.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_UnknownPhoto_ThrowsKeyNotFoundException()
    {
        await using var context = CreateContext();
        context.FaultReports.Add(new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" });
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);

        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.DeleteAsync(1, 999));
    }

    [Fact]
    public async Task DeletingFaultReport_CascadesToItsPhotos()
    {
        await using var context = CreateContext();
        var report = new FaultReport { Id = 1, ReportedById = 1, CustomerId = 1, SettlementId = 1, Title = "Leak" };
        context.FaultReports.Add(report);
        await context.SaveChangesAsync();
        var service = new FaultReportPhotoService(context);
        await service.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        context.FaultReports.Remove(report);
        await context.SaveChangesAsync();

        Assert.Empty(await context.FaultReportPhotos.ToListAsync());
    }

    private static AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AquaFlowDbContext(options);
    }
}
