using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddMeterReplacedFinalReading : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "ReplacedMeterFinalReading",
                table: "MeterReadings",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                column: "ReplacedMeterFinalReading",
                value: null);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReplacedMeterFinalReading",
                table: "MeterReadings");
        }
    }
}
