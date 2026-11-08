using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveMeterAssignments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MeterAssignments");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MeterAssignments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CollectorId = table.Column<int>(type: "int", nullable: false),
                    WaterMeterId = table.Column<int>(type: "int", nullable: false),
                    AssignedFrom = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AssignedTo = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MeterAssignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MeterAssignments_CollectorProfiles_CollectorId",
                        column: x => x.CollectorId,
                        principalTable: "CollectorProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MeterAssignments_WaterMeters_WaterMeterId",
                        column: x => x.WaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MeterAssignments_CollectorId",
                table: "MeterAssignments",
                column: "CollectorId");

            migrationBuilder.CreateIndex(
                name: "IX_MeterAssignments_WaterMeterId",
                table: "MeterAssignments",
                column: "WaterMeterId");
        }
    }
}
