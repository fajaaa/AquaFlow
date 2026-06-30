using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedSqlDemoData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "CollectorProfiles",
                columns: new[] { "Id", "AssignedAreaId", "CreatedAt", "EmployeeCode", "UpdatedAt", "UserId" },
                values: new object[] { 1, 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "COL-0001", null, 2 });

            migrationBuilder.InsertData(
                table: "CustomerProfiles",
                columns: new[] { "Id", "CreatedAt", "CustomerCode", "DefaultLanguage", "FirstName", "LastName", "Theme", "UpdatedAt", "UserId" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "CUS-0001", "bs", "Amina", "Hadziabdic", "light", null, 3 });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "Audience", "Body", "CreatedAt", "CreatedById", "SettlementId", "Title", "Type", "UpdatedAt", "ValidUntil" },
                values: new object[] { 1, "Settlement", "Planirani radovi na mrezi u naselju Centar.", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, "Planirani radovi", "PlannedWorks", null, new DateTime(2026, 6, 30, 0, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.InsertData(
                table: "PaymentSettings",
                columns: new[] { "Id", "AllowCardPayments", "AllowPayPalPayments", "CardProvider", "CreatedAt", "IsTestMode", "PayPalClientId", "PayPalMerchantEmail", "UpdatedAt", "UpdatedById" },
                values: new object[] { 1, true, false, "DemoPay", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, null, null, new DateTime(2026, 1, 10, 0, 0, 0, 0, DateTimeKind.Utc), 1 });

            migrationBuilder.InsertData(
                table: "Tariffs",
                columns: new[] { "Id", "CreatedAt", "CustomerType", "EffectiveFrom", "EffectiveTo", "FixedFee", "IsActive", "Name", "PricePerM3", "UpdatedAt" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Customer", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 3.50m, true, "Domacinstvo 2026", 1.35m, null });

            migrationBuilder.InsertData(
                table: "ServiceLocations",
                columns: new[] { "Id", "Address", "CreatedAt", "CustomerId", "IsActive", "Latitude", "LocationType", "Longitude", "SettlementId", "UpdatedAt" },
                values: new object[] { 1, "Zmaja od Bosne 12", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, true, 43.855m, "Apartment", 18.398m, 1, null });

            migrationBuilder.InsertData(
                table: "UserNotifications",
                columns: new[] { "Id", "CreatedAt", "NotificationId", "ReadAt", "UpdatedAt", "UserId" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, null, null, 3 });

            migrationBuilder.InsertData(
                table: "WaterMeters",
                columns: new[] { "Id", "CreatedAt", "InitialReading", "InstalledAt", "LastReading", "SerialNumber", "ServiceLocationId", "Status", "UpdatedAt" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 120.50m, new DateTime(2025, 12, 1, 0, 0, 0, 0, DateTimeKind.Utc), 168.40m, "WM-2026-0001", 1, "Active", null });

            migrationBuilder.InsertData(
                table: "FaultReports",
                columns: new[] { "Id", "CreatedAt", "Description", "PhotoUrl", "Priority", "ReportedById", "ResolvedAt", "ServiceLocationId", "Status", "Title", "UpdatedAt", "WaterMeterId" },
                values: new object[] { 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Pritisak vode je nizak u jutarnjim satima.", null, "Medium", 3, null, 1, "New", "Slab pritisak vode", null, 1 });

            migrationBuilder.InsertData(
                table: "Invoices",
                columns: new[] { "Id", "BillingCycleId", "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CreatedAt", "CreatedById", "CurrentReading", "CustomerId", "DueDate", "InvoiceNumber", "PreviousReading", "Status", "Subtotal", "Tax", "TotalAmount", "UpdatedAt", "WaterMeterId" },
                values: new object[] { 1, null, new DateTime(2026, 5, 1, 0, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 31, 0, 0, 0, 0, DateTimeKind.Utc), 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 168.40m, 1, new DateTime(2026, 6, 15, 0, 0, 0, 0, DateTimeKind.Utc), "INV-2026-0001", 154.20m, "Issued", 22.67m, 3.85m, 26.52m, null, 1 });

            migrationBuilder.InsertData(
                table: "MeterReadings",
                columns: new[] { "Id", "ClientUuid", "CollectorId", "ConsumptionM3", "CreatedAt", "Note", "PhotoUrl", "PreviousReadingValue", "ReadingDate", "ReadingValue", "Source", "SyncStatus", "SyncedAt", "UpdatedAt", "WaterMeterId" },
                values: new object[] { 1, "reading-demo-0001", 1, 14.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Redovno mjesecno ocitanje.", null, 154.20m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 168.40m, "Collector", "Synced", new DateTime(2026, 6, 1, 8, 10, 0, 0, DateTimeKind.Utc), null, 1 });

            migrationBuilder.InsertData(
                table: "InvoiceItems",
                columns: new[] { "Id", "Amount", "CreatedAt", "Description", "InvoiceId", "Quantity", "TariffId", "TaxRateId", "UnitPrice", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, 19.17m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 1, 14.20m, 1, null, 1.35m, null },
                    { 2, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 1, 1m, 1, null, 3.50m, null }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Status", "TransactionReference", "UpdatedAt" },
                values: new object[] { 1, 26.52m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 1, new DateTime(2026, 6, 2, 0, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Completed", "BT-2026-0001", null });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "FaultReports",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "PaymentSettings",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "CollectorProfiles",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Tariffs",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "ServiceLocations",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "CustomerProfiles",
                keyColumn: "Id",
                keyValue: 1);
        }
    }
}
