using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddAlertExpectedValues : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "ExpectedLowerBound",
                table: "WaterConsumptionAlerts",
                type: "decimal(18,3)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ExpectedUpperBound",
                table: "WaterConsumptionAlerts",
                type: "decimal(18,3)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ExpectedValue",
                table: "WaterConsumptionAlerts",
                type: "decimal(18,3)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ExpectedLowerBound",
                table: "WaterConsumptionAlerts");

            migrationBuilder.DropColumn(
                name: "ExpectedUpperBound",
                table: "WaterConsumptionAlerts");

            migrationBuilder.DropColumn(
                name: "ExpectedValue",
                table: "WaterConsumptionAlerts");
        }
    }
}
