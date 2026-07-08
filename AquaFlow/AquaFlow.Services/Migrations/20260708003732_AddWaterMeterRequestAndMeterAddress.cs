using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddWaterMeterRequestAndMeterAddress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "HouseNumber",
                table: "WaterMeters",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Street",
                table: "WaterMeters",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HouseNumber",
                table: "WaterMeterRequests",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            // Backfill any pre-existing request rows to an existing seed settlement (id 1) instead
            // of 0, so adding the Restrict FK below does not fail on an unmatched SettlementId.
            // New requests always supply their own SettlementId, so this default is only a backstop.
            migrationBuilder.AddColumn<int>(
                name: "SettlementId",
                table: "WaterMeterRequests",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<string>(
                name: "Street",
                table: "WaterMeterRequests",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "HouseNumber", "Street" },
                values: new object[] { null, null });

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_SettlementId",
                table: "WaterMeterRequests",
                column: "SettlementId");

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeterRequests_Settlements_SettlementId",
                table: "WaterMeterRequests",
                column: "SettlementId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeterRequests_Settlements_SettlementId",
                table: "WaterMeterRequests");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeterRequests_SettlementId",
                table: "WaterMeterRequests");

            migrationBuilder.DropColumn(
                name: "HouseNumber",
                table: "WaterMeters");

            migrationBuilder.DropColumn(
                name: "Street",
                table: "WaterMeters");

            migrationBuilder.DropColumn(
                name: "HouseNumber",
                table: "WaterMeterRequests");

            migrationBuilder.DropColumn(
                name: "SettlementId",
                table: "WaterMeterRequests");

            migrationBuilder.DropColumn(
                name: "Street",
                table: "WaterMeterRequests");
        }
    }
}
