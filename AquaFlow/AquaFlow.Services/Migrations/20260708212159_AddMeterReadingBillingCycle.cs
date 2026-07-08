using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddMeterReadingBillingCycle : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings");

            migrationBuilder.AddColumn<int>(
                name: "BillingCycleId",
                table: "MeterReadings",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                column: "BillingCycleId",
                value: null);

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

            migrationBuilder.AddForeignKey(
                name: "FK_MeterReadings_BillingCycles_BillingCycleId",
                table: "MeterReadings",
                column: "BillingCycleId",
                principalTable: "BillingCycles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MeterReadings_BillingCycles_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId_BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "BillingCycleId",
                table: "MeterReadings");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings",
                column: "WaterMeterId");
        }
    }
}
