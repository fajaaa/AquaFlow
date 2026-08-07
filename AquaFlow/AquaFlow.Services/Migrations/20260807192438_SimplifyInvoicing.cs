using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class SimplifyInvoicing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_InvoiceItems_TaxRates_TaxRateId",
                table: "InvoiceItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Invoices_BillingCycles_BillingCycleId",
                table: "Invoices");

            migrationBuilder.DropForeignKey(
                name: "FK_MeterReadings_BillingCycles_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropTable(
                name: "BillingCycles");

            migrationBuilder.DropTable(
                name: "TaxRates");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_Invoices_BillingCycleId",
                table: "Invoices");

            migrationBuilder.DropIndex(
                name: "IX_InvoiceItems_TaxRateId",
                table: "InvoiceItems");

            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DropColumn(
                name: "BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "BillingCycleId",
                table: "Invoices");

            migrationBuilder.DropColumn(
                name: "Tax",
                table: "Invoices");

            migrationBuilder.DropColumn(
                name: "TaxRateId",
                table: "InvoiceItems");

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                column: "TotalAmount",
                value: 22.67m);

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings",
                column: "WaterMeterId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings");

            migrationBuilder.AddColumn<int>(
                name: "BillingCycleId",
                table: "MeterReadings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BillingCycleId",
                table: "Invoices",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Tax",
                table: "Invoices",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "TaxRateId",
                table: "InvoiceItems",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BillingCycles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ClosedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PeriodFrom = table.Column<DateTime>(type: "datetime2", nullable: false),
                    PeriodTo = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BillingCycles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TaxRates",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EffectiveFrom = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EffectiveTo = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    Rate = table.Column<decimal>(type: "decimal(9,4)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaxRates", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "BillingCycles",
                columns: new[] { "Id", "ClosedAt", "CreatedAt", "Name", "PeriodFrom", "PeriodTo", "Status", "UpdatedAt" },
                values: new object[] { 1, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Juli 2026", new DateTime(2026, 7, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 7, 31, 0, 0, 0, 0, DateTimeKind.Utc), "Open", null });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 1,
                column: "TaxRateId",
                value: null);

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 2,
                column: "TaxRateId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingCycleId", "Tax", "TotalAmount" },
                values: new object[] { null, 3.85m, 26.52m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                column: "BillingCycleId",
                value: null);

            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 12, "BillingCycles.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows opening, closing, and editing billing cycles.", true, "BillingCycles", "Manage billing cycles", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 16, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 12, null, 1 });

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_BillingCycleId",
                table: "MeterReadings",
                column: "BillingCycleId");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_WaterMeterId_BillingCycleId",
                table: "MeterReadings",
                columns: new[] { "WaterMeterId", "BillingCycleId" },
                unique: true,
                filter: "[BillingCycleId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Invoices_BillingCycleId",
                table: "Invoices",
                column: "BillingCycleId");

            migrationBuilder.CreateIndex(
                name: "IX_InvoiceItems_TaxRateId",
                table: "InvoiceItems",
                column: "TaxRateId");

            migrationBuilder.AddForeignKey(
                name: "FK_InvoiceItems_TaxRates_TaxRateId",
                table: "InvoiceItems",
                column: "TaxRateId",
                principalTable: "TaxRates",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Invoices_BillingCycles_BillingCycleId",
                table: "Invoices",
                column: "BillingCycleId",
                principalTable: "BillingCycles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_MeterReadings_BillingCycles_BillingCycleId",
                table: "MeterReadings",
                column: "BillingCycleId",
                principalTable: "BillingCycles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
