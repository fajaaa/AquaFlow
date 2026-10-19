using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

// Runs on SQLite (SqliteTestDatabase), not the EF InMemory provider: RotateAsync/RevokeAsync rely
// on a real transaction around ExecuteDeleteAsync, and InMemory supports neither. Seeded users 1..6
// come from AquaFlowDbContextSeed; the seed has no refresh tokens, so each test adds its own.
public sealed class RefreshTokenServiceTests : IDisposable
{
    private readonly SqliteTestDatabase _database = new();

    public void Dispose() => _database.Dispose();

    // One session per device: refreshing on the phone must not sign the tablet out.
    [Fact]
    public async Task RotateAsync_ReplacesOnlyThePresentedToken_OtherDevicesStaySignedIn()
    {
        await SeedTokensAsync(
            (UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)),
            (UserId: 1, Raw: "user1-tablet", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 2, Raw: "user2-phone", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 3, Raw: "user3-expired", ExpiresAt: DateTime.UtcNow.AddDays(-1)));

        await using (var context = _database.CreateContext())
        {
            var service = new RefreshTokenService(context);
            var presented = await service.GetStoredTokenAsync("user1-phone");
            await service.RotateAsync(presented!, NewToken(userId: 1, raw: "user1-phone-new"));
        }

        await using var verify = _database.CreateContext();
        var verifyService = new RefreshTokenService(verify);
        Assert.Equal(2, await verify.RefreshTokens.CountAsync(rt => rt.UserId == 1));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user1-phone-new"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user1-tablet"));
        Assert.Null(await verifyService.GetStoredTokenAsync("user1-phone"));
        // Other users' valid tokens are untouched; expired ones are purged in the same transaction.
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user2-phone"));
        Assert.Null(await verifyService.GetStoredTokenAsync("user3-expired"));
    }

    // A rotated (or revoked) token can never be exchanged again: the second rotation finds nothing
    // to delete and must not issue a new token.
    [Fact]
    public async Task RotateAsync_PresentedTokenAlreadyGone_ThrowsAndIssuesNothing()
    {
        await SeedTokensAsync((UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)));

        RefreshToken presented;
        await using (var context = _database.CreateContext())
        {
            var service = new RefreshTokenService(context);
            presented = (await service.GetStoredTokenAsync("user1-phone"))!;
            await service.RotateAsync(presented, NewToken(userId: 1, raw: "first-rotation"));
        }

        await using (var context = _database.CreateContext())
        {
            await Assert.ThrowsAsync<ClientException>(() =>
                new RefreshTokenService(context).RotateAsync(presented, NewToken(userId: 1, raw: "second-rotation")));
        }

        await using var verify = _database.CreateContext();
        var verifyService = new RefreshTokenService(verify);
        Assert.Null(await verifyService.GetStoredTokenAsync("second-rotation"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("first-rotation"));
        Assert.Equal(1, await verify.RefreshTokens.CountAsync(rt => rt.UserId == 1));
    }

    // The insert fails at the database (its hash collides with another user's token on the unique
    // RefreshToken.Token index) AFTER the presented token and the expired ones were already deleted
    // inside the transaction. The rollback must bring all of them back.
    [Fact]
    public async Task RotateAsync_InsertFails_KeepsThePresentedToken()
    {
        await SeedTokensAsync(
            (UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)),
            (UserId: 1, Raw: "user1-tablet", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 2, Raw: "colliding-value", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 3, Raw: "user3-expired", ExpiresAt: DateTime.UtcNow.AddDays(-1)));

        await using (var context = _database.CreateContext())
        {
            var service = new RefreshTokenService(context);
            var presented = await service.GetStoredTokenAsync("user1-phone");
            var newToken = NewToken(userId: 1, raw: "colliding-value");
            await Assert.ThrowsAsync<DbUpdateException>(() => service.RotateAsync(presented!, newToken));

            // The failed token is not left tracked for a later SaveChanges in the same scope.
            Assert.Equal(EntityState.Detached, context.Entry(newToken).State);
        }

        await using var verify = _database.CreateContext();
        var verifyService = new RefreshTokenService(verify);
        Assert.Equal(4, await verify.RefreshTokens.CountAsync());
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user3-expired"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user1-phone"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user1-tablet"));
        Assert.Equal(2, (await verifyService.GetStoredTokenAsync("colliding-value"))!.UserId);
    }

    [Fact]
    public async Task RevokeAsync_DeletesOnlyThePresentedToken_AndReturnsItsOwner()
    {
        await SeedTokensAsync(
            (UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)),
            (UserId: 1, Raw: "user1-tablet", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 2, Raw: "user2-phone", ExpiresAt: DateTime.UtcNow.AddDays(5)));

        int? owner;
        await using (var context = _database.CreateContext())
        {
            owner = await new RefreshTokenService(context).RevokeAsync("user1-phone");
        }

        Assert.Equal(1, owner);
        await using var verify = _database.CreateContext();
        var verifyService = new RefreshTokenService(verify);
        Assert.Null(await verifyService.GetStoredTokenAsync("user1-phone"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user1-tablet"));
        Assert.NotNull(await verifyService.GetStoredTokenAsync("user2-phone"));
    }

    [Fact]
    public async Task RevokeAsync_UnknownOrAlreadyRevokedToken_ReturnsNullWithoutThrowing()
    {
        await SeedTokensAsync((UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)));

        await using var context = _database.CreateContext();
        var service = new RefreshTokenService(context);

        Assert.Null(await service.RevokeAsync("never-issued"));
        Assert.Equal(1, await service.RevokeAsync("user1-phone"));
        Assert.Null(await service.RevokeAsync("user1-phone"));
        Assert.Equal(0, await context.RefreshTokens.CountAsync());
    }

    private async Task SeedTokensAsync(params (int UserId, string Raw, DateTime ExpiresAt)[] tokens)
    {
        // Seeded through the real InsertAsync so the stored values are hashed exactly as in
        // production. InsertAsync purges expired tokens BEFORE adding its own, so an expired token
        // survives seeding as long as it is passed last.
        await using var context = _database.CreateContext();
        var service = new RefreshTokenService(context);
        foreach (var token in tokens)
        {
            await service.InsertAsync(new RefreshToken
            {
                UserId = token.UserId,
                Token = token.Raw,
                ExpiresAt = token.ExpiresAt
            });
        }
    }

    private static RefreshToken NewToken(int userId, string raw) => new()
    {
        UserId = userId,
        Token = raw,
        ExpiresAt = DateTime.UtcNow.AddDays(7)
    };
}
