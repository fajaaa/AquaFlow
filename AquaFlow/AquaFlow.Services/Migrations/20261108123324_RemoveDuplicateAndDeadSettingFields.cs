using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemoveDuplicateAndDeadSettingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReceiveEmailNotifications",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "SyncedAt",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "DefaultLanguage",
                table: "CustomerProfiles");

            migrationBuilder.DropColumn(
                name: "Theme",
                table: "CustomerProfiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ReceiveEmailNotifications",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Source",
                table: "MeterReadings",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "SyncStatus",
                table: "MeterReadings",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "SyncedAt",
                table: "MeterReadings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DefaultLanguage",
                table: "CustomerProfiles",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Theme",
                table: "CustomerProfiles",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "DefaultLanguage", "Theme" },
                values: new object[] { "bs", "light" });

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "DefaultLanguage", "Theme" },
                values: new object[] { "bs", "light" });

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "DefaultLanguage", "Theme" },
                values: new object[] { "bs", "light" });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "Source", "SyncStatus", "SyncedAt" },
                values: new object[] { "Collector", "Synced", new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });
        }
    }
}
