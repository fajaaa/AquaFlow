using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class ReplaceServiceLocationWithDirectCustomerSettlement : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Backfill CustomerId on every WaterMeter/FaultReport row via its
            // ServiceLocation, not just a single hardcoded seed row - must run
            // before ServiceLocationId is renamed/dropped and before
            // ServiceLocations is dropped below.
            migrationBuilder.AddColumn<int>(
                name: "CustomerId",
                table: "WaterMeters",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CustomerId",
                table: "FaultReports",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.Sql(@"
                UPDATE wm
                SET wm.CustomerId = sl.CustomerId
                FROM WaterMeters wm
                INNER JOIN ServiceLocations sl ON wm.ServiceLocationId = sl.Id;");

            migrationBuilder.Sql(@"
                UPDATE fr
                SET fr.CustomerId = sl.CustomerId
                FROM FaultReports fr
                INNER JOIN ServiceLocations sl ON fr.ServiceLocationId = sl.Id;");

            migrationBuilder.DropForeignKey(
                name: "FK_FaultReports_ServiceLocations_ServiceLocationId",
                table: "FaultReports");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeterRequests_ServiceLocations_ServiceLocationId",
                table: "WaterMeterRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeters_ServiceLocations_ServiceLocationId",
                table: "WaterMeters");

            migrationBuilder.DropTable(
                name: "ServiceLocations");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeterRequests_ServiceLocationId",
                table: "WaterMeterRequests");

            migrationBuilder.DropColumn(
                name: "ServiceLocationId",
                table: "WaterMeterRequests");

            migrationBuilder.RenameColumn(
                name: "ServiceLocationId",
                table: "WaterMeters",
                newName: "SettlementId");

            migrationBuilder.RenameIndex(
                name: "IX_WaterMeters_ServiceLocationId",
                table: "WaterMeters",
                newName: "IX_WaterMeters_SettlementId");

            migrationBuilder.RenameColumn(
                name: "ServiceLocationId",
                table: "FaultReports",
                newName: "SettlementId");

            migrationBuilder.RenameIndex(
                name: "IX_FaultReports_ServiceLocationId",
                table: "FaultReports",
                newName: "IX_FaultReports_SettlementId");

            migrationBuilder.AddColumn<string>(
                name: "HouseNumber",
                table: "CustomerProfiles",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SettlementId",
                table: "CustomerProfiles",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Street",
                table: "CustomerProfiles",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "HouseNumber", "SettlementId", "Street" },
                values: new object[] { "12", 1, "Zmaja od Bosne" });

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeters_CustomerId",
                table: "WaterMeters",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_FaultReports_CustomerId",
                table: "FaultReports",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomerProfiles_SettlementId",
                table: "CustomerProfiles",
                column: "SettlementId");

            migrationBuilder.AddForeignKey(
                name: "FK_CustomerProfiles_Settlements_SettlementId",
                table: "CustomerProfiles",
                column: "SettlementId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_FaultReports_CustomerProfiles_CustomerId",
                table: "FaultReports",
                column: "CustomerId",
                principalTable: "CustomerProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_FaultReports_Settlements_SettlementId",
                table: "FaultReports",
                column: "SettlementId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeters_CustomerProfiles_CustomerId",
                table: "WaterMeters",
                column: "CustomerId",
                principalTable: "CustomerProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeters_Settlements_SettlementId",
                table: "WaterMeters",
                column: "SettlementId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CustomerProfiles_Settlements_SettlementId",
                table: "CustomerProfiles");

            migrationBuilder.DropForeignKey(
                name: "FK_FaultReports_CustomerProfiles_CustomerId",
                table: "FaultReports");

            migrationBuilder.DropForeignKey(
                name: "FK_FaultReports_Settlements_SettlementId",
                table: "FaultReports");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeters_CustomerProfiles_CustomerId",
                table: "WaterMeters");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeters_Settlements_SettlementId",
                table: "WaterMeters");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeters_CustomerId",
                table: "WaterMeters");

            migrationBuilder.DropIndex(
                name: "IX_FaultReports_CustomerId",
                table: "FaultReports");

            migrationBuilder.DropIndex(
                name: "IX_CustomerProfiles_SettlementId",
                table: "CustomerProfiles");

            migrationBuilder.DropColumn(
                name: "CustomerId",
                table: "WaterMeters");

            migrationBuilder.DropColumn(
                name: "CustomerId",
                table: "FaultReports");

            migrationBuilder.DropColumn(
                name: "HouseNumber",
                table: "CustomerProfiles");

            migrationBuilder.DropColumn(
                name: "SettlementId",
                table: "CustomerProfiles");

            migrationBuilder.DropColumn(
                name: "Street",
                table: "CustomerProfiles");

            migrationBuilder.RenameColumn(
                name: "SettlementId",
                table: "WaterMeters",
                newName: "ServiceLocationId");

            migrationBuilder.RenameIndex(
                name: "IX_WaterMeters_SettlementId",
                table: "WaterMeters",
                newName: "IX_WaterMeters_ServiceLocationId");

            migrationBuilder.RenameColumn(
                name: "SettlementId",
                table: "FaultReports",
                newName: "ServiceLocationId");

            migrationBuilder.RenameIndex(
                name: "IX_FaultReports_SettlementId",
                table: "FaultReports",
                newName: "IX_FaultReports_ServiceLocationId");

            migrationBuilder.AddColumn<int>(
                name: "ServiceLocationId",
                table: "WaterMeterRequests",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "ServiceLocations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CustomerId = table.Column<int>(type: "int", nullable: false),
                    SettlementId = table.Column<int>(type: "int", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    LocationType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceLocations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceLocations_CustomerProfiles_CustomerId",
                        column: x => x.CustomerId,
                        principalTable: "CustomerProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServiceLocations_Settlements_SettlementId",
                        column: x => x.SettlementId,
                        principalTable: "Settlements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "ServiceLocations",
                columns: new[] { "Id", "Address", "CreatedAt", "CustomerId", "IsActive", "Latitude", "LocationType", "Longitude", "SettlementId", "UpdatedAt" },
                values: new object[] { 1, "Zmaja od Bosne 12", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, true, 43.855m, "Apartment", 18.398m, 1, null });

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_ServiceLocationId",
                table: "WaterMeterRequests",
                column: "ServiceLocationId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceLocations_CustomerId",
                table: "ServiceLocations",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceLocations_SettlementId",
                table: "ServiceLocations",
                column: "SettlementId");

            migrationBuilder.AddForeignKey(
                name: "FK_FaultReports_ServiceLocations_ServiceLocationId",
                table: "FaultReports",
                column: "ServiceLocationId",
                principalTable: "ServiceLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeterRequests_ServiceLocations_ServiceLocationId",
                table: "WaterMeterRequests",
                column: "ServiceLocationId",
                principalTable: "ServiceLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeters_ServiceLocations_ServiceLocationId",
                table: "WaterMeters",
                column: "ServiceLocationId",
                principalTable: "ServiceLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
