using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class SimplifyNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Settlements_SettlementId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_UserNotifications_UserId",
                table: "UserNotifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_SettlementId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "SettlementId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "ValidUntil",
                table: "Notifications");

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Audience", "Body", "Type" },
                values: new object[] { "All", "Planirani radovi na mrezi.", "Info" });

            migrationBuilder.CreateIndex(
                name: "IX_UserNotifications_UserId_NotificationId",
                table: "UserNotifications",
                columns: new[] { "UserId", "NotificationId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserNotifications_UserId_NotificationId",
                table: "UserNotifications");

            migrationBuilder.AddColumn<int>(
                name: "SettlementId",
                table: "Notifications",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ValidUntil",
                table: "Notifications",
                type: "datetime2",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Audience", "Body", "SettlementId", "Type", "ValidUntil" },
                values: new object[] { "Settlement", "Planirani radovi na mrezi u naselju Centar.", 1, "PlannedWorks", new DateTime(2026, 6, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.CreateIndex(
                name: "IX_UserNotifications_UserId",
                table: "UserNotifications",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_SettlementId",
                table: "Notifications",
                column: "SettlementId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Settlements_SettlementId",
                table: "Notifications",
                column: "SettlementId",
                principalTable: "Settlements",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
