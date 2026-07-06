using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddWaterMeterRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WaterMeterRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CustomerId = table.Column<int>(type: "int", nullable: false),
                    ServiceLocationId = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    AssignedCollectorId = table.Column<int>(type: "int", nullable: true),
                    ResultingWaterMeterId = table.Column<int>(type: "int", nullable: true),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaterMeterRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequests_CollectorProfiles_AssignedCollectorId",
                        column: x => x.AssignedCollectorId,
                        principalTable: "CollectorProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequests_CustomerProfiles_CustomerId",
                        column: x => x.CustomerId,
                        principalTable: "CustomerProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequests_ServiceLocations_ServiceLocationId",
                        column: x => x.ServiceLocationId,
                        principalTable: "ServiceLocations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequests_WaterMeters_ResultingWaterMeterId",
                        column: x => x.ResultingWaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "WaterMeterRequestStatusHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    WaterMeterRequestId = table.Column<int>(type: "int", nullable: false),
                    OldStatus = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    NewStatus = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    ChangedById = table.Column<int>(type: "int", nullable: false),
                    ChangedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaterMeterRequestStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequestStatusHistories_Users_ChangedById",
                        column: x => x.ChangedById,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaterMeterRequestStatusHistories_WaterMeterRequests_WaterMeterRequestId",
                        column: x => x.WaterMeterRequestId,
                        principalTable: "WaterMeterRequests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_AssignedCollectorId",
                table: "WaterMeterRequests",
                column: "AssignedCollectorId");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_CustomerId",
                table: "WaterMeterRequests",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_ResultingWaterMeterId",
                table: "WaterMeterRequests",
                column: "ResultingWaterMeterId");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_ServiceLocationId",
                table: "WaterMeterRequests",
                column: "ServiceLocationId");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequestStatusHistories_ChangedById",
                table: "WaterMeterRequestStatusHistories",
                column: "ChangedById");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequestStatusHistories_WaterMeterRequestId",
                table: "WaterMeterRequestStatusHistories",
                column: "WaterMeterRequestId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WaterMeterRequestStatusHistories");

            migrationBuilder.DropTable(
                name: "WaterMeterRequests");
        }
    }
}
