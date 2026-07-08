using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveTariffLegacyFieldsAddDescription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CustomerType",
                table: "Tariffs");

            migrationBuilder.DropColumn(
                name: "EffectiveFrom",
                table: "Tariffs");

            migrationBuilder.DropColumn(
                name: "EffectiveTo",
                table: "Tariffs");

            migrationBuilder.DropColumn(
                name: "FixedFee",
                table: "Tariffs");

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Tariffs",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "Tariffs",
                keyColumn: "Id",
                keyValue: 1,
                column: "Description",
                value: "Standardna tarifa za domaćinstva");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Description",
                table: "Tariffs");

            migrationBuilder.AddColumn<string>(
                name: "CustomerType",
                table: "Tariffs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "EffectiveFrom",
                table: "Tariffs",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "EffectiveTo",
                table: "Tariffs",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "FixedFee",
                table: "Tariffs",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.UpdateData(
                table: "Tariffs",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CustomerType", "EffectiveFrom", "EffectiveTo", "FixedFee" },
                values: new object[] { "Customer", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 3.50m });
        }
    }
}
