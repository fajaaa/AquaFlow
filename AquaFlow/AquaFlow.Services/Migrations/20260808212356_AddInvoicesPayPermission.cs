using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddInvoicesPayPermission : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 21, "Invoices.Pay", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows a customer to check out and pay their own issued invoices.", true, "Invoices", "Pay own invoices", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 25, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 21, null, 3 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 21);
        }
    }
}
