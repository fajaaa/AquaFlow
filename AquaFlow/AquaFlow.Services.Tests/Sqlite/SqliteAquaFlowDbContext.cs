using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.Tests.Sqlite;

// Test-only AquaFlowDbContext for SQLite (see SqliteTestDatabase). The model runs on SQLite
// unchanged except for Invoice.RowVersion: on SQL Server it is a rowversion column the server fills
// in, while SQLite has no such type, so the seeded invoices would fail its NOT NULL constraint. A
// store default supplies a value instead; no test running on SQLite reads it.
public class SqliteAquaFlowDbContext : AquaFlowDbContext
{
    public SqliteAquaFlowDbContext(DbContextOptions<AquaFlowDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Invoice>()
            .Property(invoice => invoice.RowVersion)
            .HasDefaultValueSql("randomblob(8)");
    }
}
