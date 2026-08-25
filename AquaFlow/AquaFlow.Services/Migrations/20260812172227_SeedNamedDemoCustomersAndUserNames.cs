using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedNamedDemoCustomersAndUserNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FirstName",
                table: "Users",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "LastName",
                table: "Users",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            // New Users (Id 4-6) must exist before any UpdateData below that points a FK at them
            // (CustomerProfiles.UserId, FaultReports.ReportedById, UserNotifications.UserId) -
            // moved ahead of the generated table order, which put this InsertData after those updates.
            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "DeletedAt", "Email", "FirstName", "IsActive", "IsDeleted", "LastLoginAt", "LastName", "PasswordHash", "PasswordSalt", "Phone", "UpdatedAt", "UserRoleId" },
                values: new object[,]
                {
                    { 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "denis.music@aquaflow.ba", "", true, false, null, "", "ILjw1fxwixrewU7K3VLOIm/0INU=", "AquaFlowSalt2026==", "+38762111004", null, 3 },
                    { 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "elmir.babovic@aquaflow.ba", "", true, false, null, "", "ILjw1fxwixrewU7K3VLOIm/0INU=", "AquaFlowSalt2026==", "+38762111005", null, 3 },
                    { 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "adil.joldic@aquaflow.ba", "", true, false, null, "", "ILjw1fxwixrewU7K3VLOIm/0INU=", "AquaFlowSalt2026==", "+38762111006", null, 3 }
                });

            migrationBuilder.UpdateData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 1,
                column: "AssignedAreaId",
                value: 8);

            migrationBuilder.InsertData(
                table: "CollectorProfiles",
                columns: new[] { "Id", "AssignedAreaId", "CreatedAt", "EmployeeCode", "UpdatedAt", "UserId" },
                values: new object[] { 2, 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "COL-0002", null, 3 });

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "FirstName", "HouseNumber", "LastName", "SettlementId", "Street", "UserId" },
                values: new object[] { "Denis", "15", "Music", 8, "Ozrenska", 4 });

            migrationBuilder.UpdateData(
                table: "FaultReports",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ReportedById", "SettlementId" },
                values: new object[] { 4, 8 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "CurrentReading", "PreviousReading", "Status" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 94.20m, 80.00m, "Paid" });

            migrationBuilder.InsertData(
                table: "Invoices",
                columns: new[] { "Id", "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CreatedAt", "CreatedById", "CurrentReading", "CustomerId", "InvoiceNumber", "PreviousReading", "Status", "Subtotal", "TotalAmount", "UpdatedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 2, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 108.40m, 1, "INV-2026-0002", 94.20m, "Paid", 22.6700m, 22.6700m, null, 1 },
                    { 3, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 122.60m, 1, "INV-2026-0003", 108.40m, "Paid", 22.6700m, 22.6700m, null, 1 },
                    { 4, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 136.80m, 1, "INV-2026-0004", 122.60m, "Paid", 22.6700m, 22.6700m, null, 1 },
                    { 5, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 151.00m, 1, "INV-2026-0005", 136.80m, "Issued", 22.6700m, 22.6700m, null, 1 }
                });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ClientUuid", "InvoiceId", "PreviousReadingValue", "ReadingDate", "ReadingValue", "SyncedAt" },
                values: new object[] { "reading-wm0001-01", 1, 80.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 94.20m, new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "PaidAt", "ProviderTransactionId" },
                values: new object[] { 22.6700m, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "PAY-2026-0001" });

            migrationBuilder.UpdateData(
                table: "UserNotifications",
                keyColumn: "Id",
                keyValue: 1,
                column: "UserId",
                value: 4);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Email", "FirstName", "LastName", "Phone" },
                values: new object[] { "kenan.fajic@aquaflow.ba", "Kenan", "Fajic", "+38762111000" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Email", "FirstName", "LastName", "Phone" },
                values: new object[] { "amel.fajic@aquaflow.ba", "Amel", "Fajic", "+38761111001" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Email", "FirstName", "LastName", "Phone", "UserRoleId" },
                values: new object[] { "kemal.fajic@aquaflow.ba", "Kemal", "Fajic", "+38761111002", 2 });

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "HouseNumber", "InitialReading", "LastReading", "SettlementId", "Street" },
                values: new object[] { "15", 80.00m, 151.00m, 8, "Ozrenska" });

            migrationBuilder.InsertData(
                table: "WaterMeters",
                columns: new[] { "Id", "CreatedAt", "CustomerId", "HouseNumber", "InitialReading", "InstalledAt", "LastReading", "SerialNumber", "SettlementId", "Status", "Street", "UpdatedAt" },
                values: new object[,]
                {
                    { 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "4", 60.00m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 109.00m, "WM-2026-0002", 9, "Active", "Behdzeta Mutevelica", null },
                    { 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "9", 95.00m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 152.00m, "WM-2026-0003", 1, "Active", "Mali Behar", null }
                });

            migrationBuilder.InsertData(
                table: "CustomerProfiles",
                columns: new[] { "Id", "CreatedAt", "CustomerCode", "DefaultLanguage", "FirstName", "HouseNumber", "LastName", "SettlementId", "Street", "Theme", "UpdatedAt", "UserId" },
                values: new object[,]
                {
                    { 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "CUS-0002", "bs", "Elmir", "7", "Babovic", 6, "Dobrinjske bolnice", "light", null, 5 },
                    { 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "CUS-0003", "bs", "Adil", "22", "Joldic", 11, "Saraci", "light", null, 6 }
                });

            migrationBuilder.InsertData(
                table: "InvoiceItems",
                columns: new[] { "Id", "Amount", "CreatedAt", "Description", "InvoiceId", "Quantity", "TariffId", "UnitPrice", "UpdatedAt" },
                values: new object[,]
                {
                    { 3, 19.1700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 2, 14.20m, 1, 1.35m, null },
                    { 4, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 2, 1m, 1, 3.50m, null },
                    { 5, 19.1700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 3, 14.20m, 1, 1.35m, null },
                    { 6, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 3, 1m, 1, 3.50m, null },
                    { 7, 19.1700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 4, 14.20m, 1, 1.35m, null },
                    { 8, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 4, 1m, 1, 3.50m, null },
                    { 9, 19.1700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 5, 14.20m, 1, 1.35m, null },
                    { 10, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 5, 1m, 1, 3.50m, null }
                });

            migrationBuilder.InsertData(
                table: "Invoices",
                columns: new[] { "Id", "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CreatedAt", "CreatedById", "CurrentReading", "CustomerId", "InvoiceNumber", "PreviousReading", "Status", "Subtotal", "TotalAmount", "UpdatedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 69.80m, 1, "INV-2026-0006", 60.00m, "Paid", 16.7300m, 16.7300m, null, 2 },
                    { 7, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 79.60m, 1, "INV-2026-0007", 69.80m, "Paid", 16.7300m, 16.7300m, null, 2 },
                    { 8, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 89.40m, 1, "INV-2026-0008", 79.60m, "Paid", 16.7300m, 16.7300m, null, 2 },
                    { 9, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 99.20m, 1, "INV-2026-0009", 89.40m, "Paid", 16.7300m, 16.7300m, null, 2 },
                    { 10, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 109.00m, 1, "INV-2026-0010", 99.20m, "Issued", 16.7300m, 16.7300m, null, 2 },
                    { 11, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 106.40m, 1, "INV-2026-0011", 95.00m, "Paid", 18.8900m, 18.8900m, null, 3 },
                    { 12, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 117.80m, 1, "INV-2026-0012", 106.40m, "Paid", 18.8900m, 18.8900m, null, 3 },
                    { 13, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 129.20m, 1, "INV-2026-0013", 117.80m, "Paid", 18.8900m, 18.8900m, null, 3 },
                    { 14, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 140.60m, 1, "INV-2026-0014", 129.20m, "Paid", 18.8900m, 18.8900m, null, 3 },
                    { 15, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 152.00m, 1, "INV-2026-0015", 140.60m, "Issued", 18.8900m, 18.8900m, null, 3 }
                });

            migrationBuilder.InsertData(
                table: "MeterReadings",
                columns: new[] { "Id", "ClientUuid", "CollectorId", "ConsumptionM3", "CreatedAt", "InvoiceId", "Note", "PhotoUrl", "PreviousReadingValue", "ReadingDate", "ReadingValue", "ReplacedMeterFinalReading", "Source", "SyncStatus", "SyncedAt", "TariffId", "UpdatedAt", "VoidedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 2, "reading-wm0001-02", 1, 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "Redovno mjesecno ocitanje.", null, 94.20m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 108.40m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 1 },
                    { 3, "reading-wm0001-03", 1, 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, "Redovno mjesecno ocitanje.", null, 108.40m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 122.60m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 1 },
                    { 4, "reading-wm0001-04", 1, 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 4, "Redovno mjesecno ocitanje.", null, 122.60m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 136.80m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 1 },
                    { 5, "reading-wm0001-05", 1, 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5, "Redovno mjesecno ocitanje.", null, 136.80m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 151.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 1 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Provider", "ProviderTransactionId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 2, 22.6700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 2, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0002", "Completed", null },
                    { 3, 22.6700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 3, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0003", "Completed", null },
                    { 4, 22.6700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 4, new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0004", "Completed", null }
                });

            migrationBuilder.InsertData(
                table: "InvoiceItems",
                columns: new[] { "Id", "Amount", "CreatedAt", "Description", "InvoiceId", "Quantity", "TariffId", "UnitPrice", "UpdatedAt" },
                values: new object[,]
                {
                    { 11, 13.2300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 6, 9.80m, 1, 1.35m, null },
                    { 12, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 6, 1m, 1, 3.50m, null },
                    { 13, 13.2300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 7, 9.80m, 1, 1.35m, null },
                    { 14, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 7, 1m, 1, 3.50m, null },
                    { 15, 13.2300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 8, 9.80m, 1, 1.35m, null },
                    { 16, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 8, 1m, 1, 3.50m, null },
                    { 17, 13.2300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 9, 9.80m, 1, 1.35m, null },
                    { 18, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 9, 1m, 1, 3.50m, null },
                    { 19, 13.2300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 10, 9.80m, 1, 1.35m, null },
                    { 20, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 10, 1m, 1, 3.50m, null },
                    { 21, 15.3900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 11, 11.40m, 1, 1.35m, null },
                    { 22, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 11, 1m, 1, 3.50m, null },
                    { 23, 15.3900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 12, 11.40m, 1, 1.35m, null },
                    { 24, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 12, 1m, 1, 3.50m, null },
                    { 25, 15.3900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 13, 11.40m, 1, 1.35m, null },
                    { 26, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 13, 1m, 1, 3.50m, null },
                    { 27, 15.3900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 14, 11.40m, 1, 1.35m, null },
                    { 28, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 14, 1m, 1, 3.50m, null },
                    { 29, 15.3900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 15, 11.40m, 1, 1.35m, null },
                    { 30, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 15, 1m, 1, 3.50m, null }
                });

            migrationBuilder.InsertData(
                table: "MeterReadings",
                columns: new[] { "Id", "ClientUuid", "CollectorId", "ConsumptionM3", "CreatedAt", "InvoiceId", "Note", "PhotoUrl", "PreviousReadingValue", "ReadingDate", "ReadingValue", "ReplacedMeterFinalReading", "Source", "SyncStatus", "SyncedAt", "TariffId", "UpdatedAt", "VoidedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 6, "reading-wm0002-01", 1, 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 6, "Redovno mjesecno ocitanje.", null, 60.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 69.80m, null, "Collector", "Synced", new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 2 },
                    { 7, "reading-wm0002-02", 1, 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 7, "Redovno mjesecno ocitanje.", null, 69.80m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 79.60m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 2 },
                    { 8, "reading-wm0002-03", 1, 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 8, "Redovno mjesecno ocitanje.", null, 79.60m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 89.40m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 2 },
                    { 9, "reading-wm0002-04", 1, 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 9, "Redovno mjesecno ocitanje.", null, 89.40m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 99.20m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 2 },
                    { 10, "reading-wm0002-05", 1, 9.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 10, "Redovno mjesecno ocitanje.", null, 99.20m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 109.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 2 },
                    { 11, "reading-wm0003-01", 1, 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 11, "Redovno mjesecno ocitanje.", null, 95.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 106.40m, null, "Collector", "Synced", new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 3 },
                    { 12, "reading-wm0003-02", 1, 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 12, "Redovno mjesecno ocitanje.", null, 106.40m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 117.80m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 3 },
                    { 13, "reading-wm0003-03", 1, 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 13, "Redovno mjesecno ocitanje.", null, 117.80m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 129.20m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 3 },
                    { 14, "reading-wm0003-04", 1, 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 14, "Redovno mjesecno ocitanje.", null, 129.20m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 140.60m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 3 },
                    { 15, "reading-wm0003-05", 1, 11.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 15, "Redovno mjesecno ocitanje.", null, 140.60m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 152.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 3 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Provider", "ProviderTransactionId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 5, 16.7300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 6, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0005", "Completed", null },
                    { 6, 16.7300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 7, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0006", "Completed", null },
                    { 7, 16.7300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 8, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0007", "Completed", null },
                    { 8, 16.7300m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 9, new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0008", "Completed", null },
                    { 9, 18.8900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 11, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0009", "Completed", null },
                    { 10, 18.8900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 12, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0010", "Completed", null },
                    { 11, 18.8900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 13, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0011", "Completed", null },
                    { 12, 18.8900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 14, new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0012", "Completed", null }
                });

            migrationBuilder.InsertData(
                table: "WaterMeters",
                columns: new[] { "Id", "CreatedAt", "CustomerId", "HouseNumber", "InitialReading", "InstalledAt", "LastReading", "SerialNumber", "SettlementId", "Status", "Street", "UpdatedAt" },
                values: new object[,]
                {
                    { 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "7", 70.00m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 135.00m, "WM-2026-0004", 6, "Active", "Dobrinjske bolnice", null },
                    { 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "3", 55.00m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 107.00m, "WM-2026-0005", 7, "Active", "Trg Oslobodjenja", null },
                    { 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, "22", 40.00m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 104.00m, "WM-2026-0006", 11, "Active", "Saraci", null }
                });

            migrationBuilder.InsertData(
                table: "Invoices",
                columns: new[] { "Id", "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CreatedAt", "CreatedById", "CurrentReading", "CustomerId", "InvoiceNumber", "PreviousReading", "Status", "Subtotal", "TotalAmount", "UpdatedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 16, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 83.00m, 2, "INV-2026-0016", 70.00m, "Paid", 21.0500m, 21.0500m, null, 4 },
                    { 17, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 96.00m, 2, "INV-2026-0017", 83.00m, "Paid", 21.0500m, 21.0500m, null, 4 },
                    { 18, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 109.00m, 2, "INV-2026-0018", 96.00m, "Paid", 21.0500m, 21.0500m, null, 4 },
                    { 19, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 122.00m, 2, "INV-2026-0019", 109.00m, "Paid", 21.0500m, 21.0500m, null, 4 },
                    { 20, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 135.00m, 2, "INV-2026-0020", 122.00m, "Issued", 21.0500m, 21.0500m, null, 4 },
                    { 21, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 65.40m, 2, "INV-2026-0021", 55.00m, "Paid", 17.5400m, 17.5400m, null, 5 },
                    { 22, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 75.80m, 2, "INV-2026-0022", 65.40m, "Paid", 17.5400m, 17.5400m, null, 5 },
                    { 23, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 86.20m, 2, "INV-2026-0023", 75.80m, "Paid", 17.5400m, 17.5400m, null, 5 },
                    { 24, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 96.60m, 2, "INV-2026-0024", 86.20m, "Paid", 17.5400m, 17.5400m, null, 5 },
                    { 25, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 107.00m, 2, "INV-2026-0025", 96.60m, "Paid", 17.5400m, 17.5400m, null, 5 },
                    { 26, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 1, 31, 0, 0, 0, 0, DateTimeKind.Utc), 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 52.80m, 3, "INV-2026-0026", 40.00m, "Paid", 20.7800m, 20.7800m, null, 6 },
                    { 27, new DateTime(2026, 2, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 2, 28, 0, 0, 0, 0, DateTimeKind.Utc), 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 65.60m, 3, "INV-2026-0027", 52.80m, "Paid", 20.7800m, 20.7800m, null, 6 },
                    { 28, new DateTime(2026, 3, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 3, 31, 0, 0, 0, 0, DateTimeKind.Utc), 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 78.40m, 3, "INV-2026-0028", 65.60m, "Paid", 20.7800m, 20.7800m, null, 6 },
                    { 29, new DateTime(2026, 4, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 4, 30, 0, 0, 0, 0, DateTimeKind.Utc), 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 91.20m, 3, "INV-2026-0029", 78.40m, "Issued", 20.7800m, 20.7800m, null, 6 },
                    { 30, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 104.00m, 3, "INV-2026-0030", 91.20m, "Issued", 20.7800m, 20.7800m, null, 6 }
                });

            migrationBuilder.InsertData(
                table: "InvoiceItems",
                columns: new[] { "Id", "Amount", "CreatedAt", "Description", "InvoiceId", "Quantity", "TariffId", "UnitPrice", "UpdatedAt" },
                values: new object[,]
                {
                    { 31, 17.5500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 16, 13.00m, 1, 1.35m, null },
                    { 32, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 16, 1m, 1, 3.50m, null },
                    { 33, 17.5500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 17, 13.00m, 1, 1.35m, null },
                    { 34, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 17, 1m, 1, 3.50m, null },
                    { 35, 17.5500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 18, 13.00m, 1, 1.35m, null },
                    { 36, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 18, 1m, 1, 3.50m, null },
                    { 37, 17.5500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 19, 13.00m, 1, 1.35m, null },
                    { 38, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 19, 1m, 1, 3.50m, null },
                    { 39, 17.5500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 20, 13.00m, 1, 1.35m, null },
                    { 40, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 20, 1m, 1, 3.50m, null },
                    { 41, 14.0400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 21, 10.40m, 1, 1.35m, null },
                    { 42, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 21, 1m, 1, 3.50m, null },
                    { 43, 14.0400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 22, 10.40m, 1, 1.35m, null },
                    { 44, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 22, 1m, 1, 3.50m, null },
                    { 45, 14.0400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 23, 10.40m, 1, 1.35m, null },
                    { 46, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 23, 1m, 1, 3.50m, null },
                    { 47, 14.0400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 24, 10.40m, 1, 1.35m, null },
                    { 48, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 24, 1m, 1, 3.50m, null },
                    { 49, 14.0400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 25, 10.40m, 1, 1.35m, null },
                    { 50, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 25, 1m, 1, 3.50m, null },
                    { 51, 17.2800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 26, 12.80m, 1, 1.35m, null },
                    { 52, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 26, 1m, 1, 3.50m, null },
                    { 53, 17.2800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 27, 12.80m, 1, 1.35m, null },
                    { 54, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 27, 1m, 1, 3.50m, null },
                    { 55, 17.2800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 28, 12.80m, 1, 1.35m, null },
                    { 56, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 28, 1m, 1, 3.50m, null },
                    { 57, 17.2800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 29, 12.80m, 1, 1.35m, null },
                    { 58, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 29, 1m, 1, 3.50m, null },
                    { 59, 17.2800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 30, 12.80m, 1, 1.35m, null },
                    { 60, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 30, 1m, 1, 3.50m, null }
                });

            migrationBuilder.InsertData(
                table: "MeterReadings",
                columns: new[] { "Id", "ClientUuid", "CollectorId", "ConsumptionM3", "CreatedAt", "InvoiceId", "Note", "PhotoUrl", "PreviousReadingValue", "ReadingDate", "ReadingValue", "ReplacedMeterFinalReading", "Source", "SyncStatus", "SyncedAt", "TariffId", "UpdatedAt", "VoidedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 16, "reading-wm0004-01", 2, 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 16, "Redovno mjesecno ocitanje.", null, 70.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 83.00m, null, "Collector", "Synced", new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 4 },
                    { 17, "reading-wm0004-02", 2, 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 17, "Redovno mjesecno ocitanje.", null, 83.00m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 96.00m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 4 },
                    { 18, "reading-wm0004-03", 2, 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 18, "Redovno mjesecno ocitanje.", null, 96.00m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 109.00m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 4 },
                    { 19, "reading-wm0004-04", 2, 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 19, "Redovno mjesecno ocitanje.", null, 109.00m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 122.00m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 4 },
                    { 20, "reading-wm0004-05", 2, 13.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 20, "Redovno mjesecno ocitanje.", null, 122.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 135.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 4 },
                    { 21, "reading-wm0005-01", 2, 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 21, "Redovno mjesecno ocitanje.", null, 55.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 65.40m, null, "Collector", "Synced", new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 5 },
                    { 22, "reading-wm0005-02", 2, 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 22, "Redovno mjesecno ocitanje.", null, 65.40m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 75.80m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 5 },
                    { 23, "reading-wm0005-03", 2, 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 23, "Redovno mjesecno ocitanje.", null, 75.80m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 86.20m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 5 },
                    { 24, "reading-wm0005-04", 2, 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 24, "Redovno mjesecno ocitanje.", null, 86.20m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 96.60m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 5 },
                    { 25, "reading-wm0005-05", 2, 10.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 25, "Redovno mjesecno ocitanje.", null, 96.60m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 107.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 5 },
                    { 26, "reading-wm0006-01", 2, 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 26, "Redovno mjesecno ocitanje.", null, 40.00m, new DateTime(2026, 2, 1, 8, 0, 0, 0, DateTimeKind.Utc), 52.80m, null, "Collector", "Synced", new DateTime(2026, 2, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 6 },
                    { 27, "reading-wm0006-02", 2, 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 27, "Redovno mjesecno ocitanje.", null, 52.80m, new DateTime(2026, 3, 1, 8, 0, 0, 0, DateTimeKind.Utc), 65.60m, null, "Collector", "Synced", new DateTime(2026, 3, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 6 },
                    { 28, "reading-wm0006-03", 2, 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 28, "Redovno mjesecno ocitanje.", null, 65.60m, new DateTime(2026, 4, 1, 8, 0, 0, 0, DateTimeKind.Utc), 78.40m, null, "Collector", "Synced", new DateTime(2026, 4, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 6 },
                    { 29, "reading-wm0006-04", 2, 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 29, "Redovno mjesecno ocitanje.", null, 78.40m, new DateTime(2026, 5, 1, 8, 0, 0, 0, DateTimeKind.Utc), 91.20m, null, "Collector", "Synced", new DateTime(2026, 5, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 6 },
                    { 30, "reading-wm0006-05", 2, 12.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 30, "Redovno mjesecno ocitanje.", null, 91.20m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 104.00m, null, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), 1, null, null, 6 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Provider", "ProviderTransactionId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 13, 21.0500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 16, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0013", "Completed", null },
                    { 14, 21.0500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 17, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0014", "Completed", null },
                    { 15, 21.0500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 18, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0015", "Completed", null },
                    { 16, 21.0500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 19, new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0016", "Completed", null },
                    { 17, 17.5400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 21, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0017", "Completed", null },
                    { 18, 17.5400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 22, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0018", "Completed", null },
                    { 19, 17.5400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 23, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0019", "Completed", null },
                    { 20, 17.5400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 24, new DateTime(2026, 5, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0020", "Completed", null },
                    { 21, 17.5400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 25, new DateTime(2026, 6, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0021", "Completed", null },
                    { 22, 20.7800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 26, new DateTime(2026, 2, 5, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0022", "Completed", null },
                    { 23, 20.7800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 27, new DateTime(2026, 3, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0023", "Completed", null },
                    { 24, 20.7800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 28, new DateTime(2026, 4, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0024", "Completed", null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 37);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 38);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 39);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 40);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 41);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 42);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 43);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 44);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 45);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 46);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 47);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 48);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 49);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 50);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 51);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 52);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 53);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 54);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 55);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 56);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 57);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 58);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 59);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 60);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DropColumn(
                name: "FirstName",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LastName",
                table: "Users");

            migrationBuilder.UpdateData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 1,
                column: "AssignedAreaId",
                value: 1);

            migrationBuilder.UpdateData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "FirstName", "HouseNumber", "LastName", "SettlementId", "Street", "UserId" },
                values: new object[] { "Amina", "12", "Hadziabdic", 1, "Zmaja od Bosne", 3 });

            migrationBuilder.UpdateData(
                table: "FaultReports",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ReportedById", "SettlementId" },
                values: new object[] { 3, 1 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "CurrentReading", "PreviousReading", "Status" },
                values: new object[] { new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 168.40m, 154.20m, "Issued" });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ClientUuid", "InvoiceId", "PreviousReadingValue", "ReadingDate", "ReadingValue", "SyncedAt" },
                values: new object[] { "reading-demo-0001", null, 154.20m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 168.40m, new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "PaidAt", "ProviderTransactionId" },
                values: new object[] { 26.52m, new DateTime(2026, 6, 2, 0, 0, 0, 0, DateTimeKind.Utc), "BT-2026-0001" });

            migrationBuilder.UpdateData(
                table: "UserNotifications",
                keyColumn: "Id",
                keyValue: 1,
                column: "UserId",
                value: 3);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Email", "Phone" },
                values: new object[] { "admin@aquaflow.ba", "+38733111222" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Email", "Phone" },
                values: new object[] { "collector@aquaflow.ba", "+38761111222" });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Email", "Phone", "UserRoleId" },
                values: new object[] { "customer@aquaflow.ba", "+38762111222", 3 });

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "HouseNumber", "InitialReading", "LastReading", "SettlementId", "Street" },
                values: new object[] { null, 120.50m, 168.40m, 1, null });

            // Deleted last: CustomerProfiles.UserId/FaultReports.ReportedById/UserNotifications.UserId
            // are only reverted off of User 4 by the UpdateData calls above, not deleted outright
            // (unlike Users 5/6, whose CustomerProfiles rows are deleted), so this FK reference must
            // outlive all of them.
            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 4);
        }
    }
}
