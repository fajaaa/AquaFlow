using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveCollectorProfileAssignedArea : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CollectorProfiles_Settlements_AssignedAreaId",
                table: "CollectorProfiles");

            migrationBuilder.DropIndex(
                name: "IX_CollectorProfiles_AssignedAreaId",
                table: "CollectorProfiles");

            migrationBuilder.DropColumn(
                name: "AssignedAreaId",
                table: "CollectorProfiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AssignedAreaId",
                table: "CollectorProfiles",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 1,
                column: "AssignedAreaId",
                value: 8);

            migrationBuilder.UpdateData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 2,
                column: "AssignedAreaId",
                value: 6);

            migrationBuilder.CreateIndex(
                name: "IX_CollectorProfiles_AssignedAreaId",
                table: "CollectorProfiles",
                column: "AssignedAreaId");

            migrationBuilder.AddForeignKey(
                name: "FK_CollectorProfiles_Settlements_AssignedAreaId",
                table: "CollectorProfiles",
                column: "AssignedAreaId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
