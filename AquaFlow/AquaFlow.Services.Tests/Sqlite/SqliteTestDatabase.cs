using AquaFlow.Services.Database;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.Tests.Sqlite;

// A throwaway SQLite in-memory database with the full AquaFlow schema + HasData seed, for the few
// tests that must prove a rollback. The rest of this project uses the EF InMemory provider, which
// ignores transactions and so cannot show that a failed multi-step write left nothing behind;
// SQLite has real transactions and real constraints (FKs, unique indexes). The connection stays
// open for the database's lifetime, because an in-memory SQLite database lives only as long as its
// connection. Create one per test (e.g. in the test class constructor) and dispose it after.
public sealed class SqliteTestDatabase : IDisposable
{
    private readonly SqliteConnection _connection;

    public SqliteTestDatabase()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        using var context = CreateContext();
        context.Database.EnsureCreated();
    }

    // Each call is a separate context over the same database - use a fresh one to verify what is
    // actually committed, rather than what another context still tracks.
    public AquaFlowDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseSqlite(_connection)
            .Options;

        return new SqliteAquaFlowDbContext(options);
    }

    public void Dispose() => _connection.Dispose();
}
