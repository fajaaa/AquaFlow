using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveRecommendations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Recommendations");

            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 22);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Recommendations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CustomerId = table.Column<int>(type: "int", nullable: false),
                    WaterMeterId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Recommendations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Recommendations_CustomerProfiles_CustomerId",
                        column: x => x.CustomerId,
                        principalTable: "CustomerProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Recommendations_WaterMeters_WaterMeterId",
                        column: x => x.WaterMeterId,
                        principalTable: "WaterMeters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 22, "Recommendations.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows viewing, resolving, and recomputing consumption-based recommendations.", true, "Recommendations", "Manage recommendations", null });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 26, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 22, null, 1 });

            migrationBuilder.CreateIndex(
                name: "IX_Recommendations_CustomerId",
                table: "Recommendations",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_Recommendations_WaterMeterId",
                table: "Recommendations",
                column: "WaterMeterId");
        }
    }
}
