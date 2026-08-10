using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddMeterReadingClientUuidUniqueIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_WaterMeterId_ClientUuid",
                table: "MeterReadings",
                columns: new[] { "WaterMeterId", "ClientUuid" },
                unique: true,
                filter: "[ClientUuid] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_WaterMeterId_ClientUuid",
                table: "MeterReadings");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_WaterMeterId",
                table: "MeterReadings",
                column: "WaterMeterId");
        }
    }
}
