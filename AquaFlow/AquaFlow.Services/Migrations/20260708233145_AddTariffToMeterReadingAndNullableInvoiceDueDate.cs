using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddTariffToMeterReadingAndNullableInvoiceDueDate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TariffId",
                table: "MeterReadings",
                type: "int",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "DueDate",
                table: "Invoices",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                column: "TariffId",
                value: 1);

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_TariffId",
                table: "MeterReadings",
                column: "TariffId");

            migrationBuilder.AddForeignKey(
                name: "FK_MeterReadings_Tariffs_TariffId",
                table: "MeterReadings",
                column: "TariffId",
                principalTable: "Tariffs",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MeterReadings_Tariffs_TariffId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_TariffId",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "TariffId",
                table: "MeterReadings");

            migrationBuilder.AlterColumn<DateTime>(
                name: "DueDate",
                table: "Invoices",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);
        }
    }
}
