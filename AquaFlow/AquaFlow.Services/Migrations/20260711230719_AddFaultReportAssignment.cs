using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddFaultReportAssignment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.AddColumn<int>(
                name: "AssignedCollectorId",
                table: "FaultReports",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "FaultReports",
                keyColumn: "Id",
                keyValue: 1,
                column: "AssignedCollectorId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_FaultReports_AssignedCollectorId",
                table: "FaultReports",
                column: "AssignedCollectorId");

            migrationBuilder.AddForeignKey(
                name: "FK_FaultReports_CollectorProfiles_AssignedCollectorId",
                table: "FaultReports",
                column: "AssignedCollectorId",
                principalTable: "CollectorProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FaultReports_CollectorProfiles_AssignedCollectorId",
                table: "FaultReports");

            migrationBuilder.DropIndex(
                name: "IX_FaultReports_AssignedCollectorId",
                table: "FaultReports");

            migrationBuilder.DropColumn(
                name: "AssignedCollectorId",
                table: "FaultReports");

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 9, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 6, null, 2 });
        }
    }
}
