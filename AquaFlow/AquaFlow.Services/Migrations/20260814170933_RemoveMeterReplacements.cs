using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveMeterReplacements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MeterReplacements");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MeterReplacements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NewWaterMeterId = table.Column<int>(type: "int", nullable: false),
                    OldWaterMeterId = table.Column<int>(type: "int", nullable: false),
                    ReplacedById = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    NewInitialReading = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    OldFinalReading = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ReplacementDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MeterReplacements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MeterReplacements_Users_ReplacedById",
                        column: x => x.ReplacedById,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MeterReplacements_WaterMeters_NewWaterMeterId",
                        column: x => x.NewWaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MeterReplacements_WaterMeters_OldWaterMeterId",
                        column: x => x.OldWaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MeterReplacements_NewWaterMeterId",
                table: "MeterReplacements",
                column: "NewWaterMeterId");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReplacements_OldWaterMeterId",
                table: "MeterReplacements",
                column: "OldWaterMeterId");

            migrationBuilder.CreateIndex(
                name: "IX_MeterReplacements_ReplacedById",
                table: "MeterReplacements",
                column: "ReplacedById");
        }
    }
}
