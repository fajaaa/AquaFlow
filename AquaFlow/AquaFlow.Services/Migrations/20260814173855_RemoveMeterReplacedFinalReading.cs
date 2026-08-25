using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveMeterReplacedFinalReading : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReplacedMeterFinalReading",
                table: "MeterReadings");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
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

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                column: "ReplacedMeterFinalReading",
                value: null);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                column: "ReplacedMeterFinalReading",
                value: null);
        }
    }
}
