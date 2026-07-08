using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddBillingCycleReadAccess : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "BillingCycles",
                columns: new[] { "Id", "ClosedAt", "CreatedAt", "Name", "PeriodFrom", "PeriodTo", "Status", "UpdatedAt" },
                values: new object[] { 1, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Juli 2026", new DateTime(2026, 7, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 7, 31, 0, 0, 0, 0, DateTimeKind.Utc), "Open", null });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "BillingCycles",
                keyColumn: "Id",
                keyValue: 1);
        }
    }
}
