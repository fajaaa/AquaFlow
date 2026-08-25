using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedHourlyReadingsAndInvoices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-h01", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-h02", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-h03", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-h04", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-h05", "Redovno satno ocitanje.", new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 12,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 13,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 14,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 15,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 16,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 17,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 18,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 19,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 20,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 21,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 14, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 22,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 23,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 24,
                column: "PaidAt",
                value: new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0001-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0002-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0003-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0004-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0005-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-01", "Redovno mjesecno ocitanje.", new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-02", "Redovno mjesecno ocitanje.", new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-03", "Redovno mjesecno ocitanje.", new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-04", "Redovno mjesecno ocitanje.", new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "ClientUuid", "Note", "ReadingDate", "SyncedAt" },
                values: new object[] { "reading-wm0006-05", "Redovno mjesecno ocitanje.", new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4,
                column: "PaidAt",
                value: new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8,
                column: "PaidAt",
                value: new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 12,
                column: "PaidAt",
                value: new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 13,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 14,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 15,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 16,
                column: "PaidAt",
                value: new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 17,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 18,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 19,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 20,
                column: "PaidAt",
                value: new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 21,
                column: "PaidAt",
                value: new DateTime(2026, 6, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 22,
                column: "PaidAt",
                value: new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 23,
                column: "PaidAt",
                value: new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 24,
                column: "PaidAt",
                value: new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc));
        }
    }
}
