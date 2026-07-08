using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddBillingCyclesManage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 12, "BillingCycles.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows opening, closing, and editing billing cycles.", true, "BillingCycles", "Manage billing cycles", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 16, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 12, null, 1 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 12);
        }
    }
}
