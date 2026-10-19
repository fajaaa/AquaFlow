using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests;

// Runs on SQLite (SqliteTestDatabase), not the EF InMemory provider: RotateAsync relies on a real
// transaction around ExecuteDeleteAsync, and InMemory supports neither. Seeded users 1..6 come from
// AquaFlowDbContextSeed; the seed has no refresh tokens, so each test adds its own.
public sealed class RefreshTokenServiceTests : IDisposable
{
    private readonly SqliteTestDatabase _database = new();

    public void Dispose() => _database.Dispose();

    [Fact]
    public async Task RotateAsync_ReplacesAllOfTheUsersTokensWithTheNewOne()
    {
        await SeedTokensAsync(
            (UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)),
            (UserId: 1, Raw: "user1-tablet", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 2, Raw: "user2-phone", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 3, Raw: "user3-expired", ExpiresAt: DateTime.UtcNow.AddDays(-1)));

        await using (var context = _database.CreateContext())
        {
            await new RefreshTokenService(context).RotateAsync(NewToken(userId: 1, raw: "user1-new"));
        }

        await using var verify = _database.CreateContext();
        var service = new RefreshTokenService(verify);
        Assert.Equal(1, await verify.RefreshTokens.CountAsync(rt => rt.UserId == 1));
        Assert.NotNull(await service.GetStoredTokenAsync("user1-new"));
        Assert.Null(await service.GetStoredTokenAsync("user1-phone"));
        Assert.Null(await service.GetStoredTokenAsync("user1-tablet"));
        // Other users' valid tokens are untouched; expired ones are purged in the same transaction.
        Assert.NotNull(await service.GetStoredTokenAsync("user2-phone"));
        Assert.Null(await service.GetStoredTokenAsync("user3-expired"));
    }

    // The insert fails at the database (its hash collides with another user's token on the unique
    // RefreshToken.Token index) AFTER the user's old tokens and the expired ones were already deleted
    // inside the transaction. The rollback must bring all of them back - before this change the old
    // tokens were gone for good and the user was logged out everywhere.
    [Fact]
    public async Task RotateAsync_InsertFails_KeepsTheUsersOldTokens()
    {
        await SeedTokensAsync(
            (UserId: 1, Raw: "user1-phone", ExpiresAt: DateTime.UtcNow.AddDays(3)),
            (UserId: 1, Raw: "user1-tablet", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 2, Raw: "colliding-value", ExpiresAt: DateTime.UtcNow.AddDays(5)),
            (UserId: 3, Raw: "user3-expired", ExpiresAt: DateTime.UtcNow.AddDays(-1)));

        await using (var context = _database.CreateContext())
        {
            var newToken = NewToken(userId: 1, raw: "colliding-value");
            await Assert.ThrowsAsync<DbUpdateException>(() => new RefreshTokenService(context).RotateAsync(newToken));

            // The failed token is not left tracked for a later SaveChanges in the same scope.
            Assert.Equal(EntityState.Detached, context.Entry(newToken).State);
        }

        await using var verify = _database.CreateContext();
        var service = new RefreshTokenService(verify);
        Assert.Equal(4, await verify.RefreshTokens.CountAsync());
        Assert.NotNull(await service.GetStoredTokenAsync("user3-expired"));
        Assert.NotNull(await service.GetStoredTokenAsync("user1-phone"));
        Assert.NotNull(await service.GetStoredTokenAsync("user1-tablet"));
        Assert.Equal(2, (await service.GetStoredTokenAsync("colliding-value"))!.UserId);
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
