using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveReadingRoutes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ReadingRouteItems");

            migrationBuilder.DropTable(
                name: "ReadingRoutes");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ReadingRoutes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CollectorId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    ScheduledDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadingRoutes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReadingRoutes_CollectorProfiles_CollectorId",
                        column: x => x.CollectorId,
                        principalTable: "CollectorProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ReadingRouteItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReadingRouteId = table.Column<int>(type: "int", nullable: false),
                    WaterMeterId = table.Column<int>(type: "int", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadingRouteItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReadingRouteItems_ReadingRoutes_ReadingRouteId",
                        column: x => x.ReadingRouteId,
                        principalTable: "ReadingRoutes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ReadingRouteItems_WaterMeters_WaterMeterId",
                        column: x => x.WaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ReadingRouteItems_ReadingRouteId",
                table: "ReadingRouteItems",
                column: "ReadingRouteId");

            migrationBuilder.CreateIndex(
                name: "IX_ReadingRouteItems_WaterMeterId",
                table: "ReadingRouteItems",
                column: "WaterMeterId");

            migrationBuilder.CreateIndex(
                name: "IX_ReadingRoutes_CollectorId",
                table: "ReadingRoutes",
                column: "CollectorId");
        }
    }
}
