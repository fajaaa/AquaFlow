using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveRefundedPaymentStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM [PaymentStatuses] WHERE [Code] = 'Refunded' AND NOT EXISTS (SELECT 1 FROM [Payments] WHERE [Status] = 'Refunded')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "PaymentStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[] { 4, "Refunded", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Refundirana", "Erstattet", "Refunded", 40, null });
        }
    }
}
