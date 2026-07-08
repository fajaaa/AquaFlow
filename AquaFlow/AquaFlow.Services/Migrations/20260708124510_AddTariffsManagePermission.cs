using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddTariffsManagePermission : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 11, "Tariffs.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows creating, updating, and deleting tariffs.", true, "Tariffs", "Manage tariffs", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 15, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 11, null, 1 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 11);
        }
    }
}
