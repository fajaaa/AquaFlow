using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.FaultReportStateMachine;
using AquaFlow.Services.Tests.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

// SQLite (real transactions) rather than InMemory, to show a rejected photo leaves no report behind.
public sealed class FaultReportCreateWithPhotosTests : IDisposable
{
    private readonly SqliteTestDatabase _database = new();

    public void Dispose() => _database.Dispose();

    [Fact]
    public async Task CreateWithPhotosAsync_ValidPhotos_SavesReportAndBothPhotos()
    {
        var reporterId = await SeedAsync();
        await using var context = _database.CreateContext();
        var service = FaultReportServiceTests.CreateService(context);

        var response = await service.CreateWithPhotosAsync(
            Request(reporterId),
            [
                new FaultReportPhotoUpload([1, 2, 3], "image/jpeg", "a.jpg"),
                new FaultReportPhotoUpload([4, 5], "image/png", "b.png")
            ],
            reporterId);

        await using var verify = _database.CreateContext();
        var report = await verify.FaultReports.SingleAsync(f => f.Id == response.Id);
        Assert.Equal(FaultReportStatus.New, report.Status);
        Assert.Equal(2, await verify.FaultReportPhotos.CountAsync(p => p.FaultReportId == report.Id));
    }

    [Fact]
    public async Task CreateWithPhotosAsync_InvalidPhoto_LeavesNoReportAndNoPhotos()
    {
        var reporterId = await SeedAsync();
        await using var before = _database.CreateContext();
        var reportsBefore = await before.FaultReports.CountAsync();
        var photosBefore = await before.FaultReportPhotos.CountAsync();
        await using var context = _database.CreateContext();
        var service = FaultReportServiceTests.CreateService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.CreateWithPhotosAsync(
            Request(reporterId),
            [
                new FaultReportPhotoUpload([1, 2, 3], "image/jpeg", "a.jpg"),
                new FaultReportPhotoUpload([], "image/png", "empty.png")
            ],
            reporterId));

        await using var verify = _database.CreateContext();
        Assert.Equal(reportsBefore, await verify.FaultReports.CountAsync());
        Assert.Equal(photosBefore, await verify.FaultReportPhotos.CountAsync());
    }

    private static FaultReportInsertRequest Request(int reporterId) => new()
    {
        ReportedById = reporterId,
        SettlementId = 1,
        Title = "Broken pipe",
        Description = "Water leaking.",
        Status = FaultReportStatus.New
    };

    // Returns an existing seeded user id and makes sure a settlement with id 1 exists.
    private async Task<int> SeedAsync()
    {
        await using var context = _database.CreateContext();
        if (!await context.Settlements.AnyAsync(s => s.Id == 1))
        {
            var municipalityId = await context.Municipalities.Select(m => m.Id).FirstAsync();
            context.Settlements.Add(new Settlement { Id = 1, Name = "Test", MunicipalityId = municipalityId, PostalCode = "71000" });
            await context.SaveChangesAsync();
        }

        return await context.Users.Select(u => u.Id).FirstAsync();
    }
}
