using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddInvoicesManagePermission : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 13, "Invoices.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows issuing, cancelling, and recording payments against invoices.", true, "Invoices", "Manage invoices", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 17, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 13, null, 1 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 13);
        }
    }
}
