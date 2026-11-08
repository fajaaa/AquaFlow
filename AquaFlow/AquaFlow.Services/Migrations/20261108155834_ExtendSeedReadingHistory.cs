using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class ExtendSeedReadingHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "ConsumptionAlertTypes",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Name", "NameDe", "NameEn" },
                values: new object[] { "Neuobičajena potrošnja", "Ungewöhnlicher Verbrauch", "Unusual consumption" });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.8500m, 11.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 21.6000m, 16.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.4700m, 12.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 21.3300m, 15.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.0400m, 10.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 22.4100m, 16.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.1700m, 14.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 11.6100m, 8.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.2000m, 12.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 11.0700m, 8.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.3900m, 11.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.2300m, 9.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 10.2600m, 7.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.3100m, 10.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 20.5200m, 15.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 31,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.1500m, 9.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 33,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.5500m, 13.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 35,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.6900m, 9.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 37,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.2800m, 12.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 39,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.7100m, 14.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 41,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.7700m, 10.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 43,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.7400m, 12.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 45,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 18.3600m, 13.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 47,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.9300m, 11.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 49,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.1700m, 14.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 51,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.0100m, 12.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 53,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 20.7900m, 15.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 55,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.5000m, 10.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 57,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.9600m, 9.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 59,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.7400m, 12.40m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 11.00m, 64.00m, 53.00m, 18.3500m, 18.3500m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 16.00m, 80.00m, 64.00m, 25.1000m, 25.1000m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 12.20m, 92.20m, 80.00m, 19.9700m, 19.9700m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 15.80m, 108.00m, 92.20m, 24.8300m, 24.8300m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 10.40m, 118.40m, 108.00m, "Paid", 17.5400m, 17.5400m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 16.60m, 135.00m, 118.40m, 25.9100m, 25.9100m, 1 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 14.20m, 149.20m, 135.00m, "Issued", 22.6700m, 22.6700m, 1 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 8.60m, 48.00m, 39.40m, 15.1100m, 15.1100m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 12.00m, 60.00m, 48.00m, 19.7000m, 19.7000m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 8.20m, 68.20m, 60.00m, "Paid", 14.5700m, 14.5700m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 11.40m, 79.60m, 68.20m, 18.8900m, 18.8900m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 9.80m, 89.40m, 79.60m, 16.7300m, 16.7300m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 7.60m, 97.00m, 89.40m, 13.7600m, 13.7600m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.60m, 107.60m, 97.00m, "Issued", 17.8100m, 17.8100m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 15.20m, 86.00m, 70.80m, "Paid", 24.0200m, 24.0200m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 9.00m, 95.00m, 1, 86.00m, 15.6500m, 15.6500m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 13.00m, 108.00m, 1, 95.00m, 21.0500m, 21.0500m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 9.40m, 117.40m, 1, 108.00m, 16.1900m, 16.1900m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 12.80m, 130.20m, 1, 117.40m, 20.7800m, 20.7800m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 14.60m, 144.80m, 1, 130.20m, "Paid", 23.2100m, 23.2100m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.20m, 155.00m, 1, 144.80m, "Issued", 17.2700m, 17.2700m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 12.40m, 56.40m, 44.00m, 20.2400m, 20.2400m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 13.60m, 70.00m, 56.40m, 21.8600m, 21.8600m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 11.80m, 81.80m, 70.00m, 19.4300m, 19.4300m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 14.20m, 96.00m, 81.80m, 22.6700m, 22.6700m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 12.60m, 108.60m, 2, 96.00m, 20.5100m, 20.5100m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 15.40m, 124.00m, 2, 108.60m, 24.2900m, 24.2900m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.00m, 134.00m, 2, 124.00m, "Issued", 17.0000m, 17.0000m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 9.60m, 42.60m, 2, 33.00m, "Paid", 16.4600m, 16.4600m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 12.40m, 55.00m, 2, 42.60m, "Paid", 20.2400m, 20.2400m, 5 });

            migrationBuilder.InsertData(
                table: "Invoices",
                columns: new[] { "Id", "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CreatedAt", "CreatedById", "CurrentReading", "CustomerId", "InvoiceNumber", "PreviousReading", "Status", "Subtotal", "TotalAmount", "UpdatedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 31, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 9.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 64.00m, 2, "INV-2026-0031", 55.00m, "Paid", 15.6500m, 15.6500m, null, 5 },
                    { 32, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 11.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 75.60m, 2, "INV-2026-0032", 64.00m, "Paid", 19.1600m, 19.1600m, null, 5 },
                    { 33, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 8.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 84.00m, 2, "INV-2026-0033", 75.60m, "Paid", 14.8400m, 14.8400m, null, 5 },
                    { 34, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 12.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 96.20m, 2, "INV-2026-0034", 84.00m, "Paid", 19.9700m, 19.9700m, null, 5 },
                    { 35, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 107.00m, 2, "INV-2026-0035", 96.20m, "Paid", 18.0800m, 18.0800m, null, 5 },
                    { 36, new DateTime(2026, 6, 1, 5, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 11.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 26.40m, 3, "INV-2026-0036", 14.80m, "Paid", 19.1600m, 19.1600m, null, 6 },
                    { 37, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 13.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 40.00m, 3, "INV-2026-0037", 26.40m, "Paid", 21.8600m, 21.8600m, null, 6 },
                    { 38, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 10.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 50.60m, 3, "INV-2026-0038", 40.00m, "Paid", 17.8100m, 17.8100m, null, 6 },
                    { 39, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 13.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 64.00m, 3, "INV-2026-0039", 50.60m, "Paid", 21.5900m, 21.5900m, null, 6 },
                    { 40, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 11.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 75.20m, 3, "INV-2026-0040", 64.00m, "Paid", 18.6200m, 18.6200m, null, 6 },
                    { 41, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 14.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 90.00m, 3, "INV-2026-0041", 75.20m, "Issued", 23.4800m, 23.4800m, null, 6 },
                    { 42, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 9.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, 99.60m, 3, "INV-2026-0042", 90.00m, "Issued", 16.4600m, 16.4600m, null, 6 }
                });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 11.00m, 53.00m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 64.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 16.00m, 64.00m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 80.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 12.20m, 80.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 92.20m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 15.80m, 92.20m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 108.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 10.40m, 108.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 118.40m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0001-h06", 16.60m, 118.40m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 135.00m, 1 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0001-h07", 14.20m, 135.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 149.20m, 1 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h01", 8.60m, 39.40m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 48.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h02", 12.00m, 48.00m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 60.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h03", 8.20m, 60.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 68.20m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h04", 11.40m, 68.20m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 79.60m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h05", 9.80m, 79.60m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 89.40m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h06", 7.60m, 89.40m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 97.00m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h07", 10.60m, 97.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 107.60m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0003-h01", 15.20m, 70.80m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 86.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h02", 1, 9.00m, 86.00m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 95.00m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h03", 1, 13.00m, 95.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 108.00m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h04", 1, 9.40m, 108.00m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 117.40m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h05", 1, 12.80m, 117.40m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 130.20m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h06", 1, 14.60m, 130.20m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 144.80m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h07", 1, 10.20m, 144.80m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 155.00m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h01", 12.40m, 44.00m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 56.40m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h02", 13.60m, 56.40m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 70.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h03", 11.80m, 70.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 81.80m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h04", 14.20m, 81.80m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 96.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h05", 12.60m, 96.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 108.60m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h06", 15.40m, 108.60m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 124.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h07", 10.00m, 124.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 134.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h01", 9.60m, 33.00m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 42.60m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h02", 12.40m, 42.60m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 55.00m, 5 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 18.3500m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 25.1000m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 19.9700m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 24.8300m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 17.5400m, 5, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 25.9100m, 6, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 15.1100m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 19.7000m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 14.5700m, 10 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 18.8900m, 11 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 16.7300m, 12 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 13.7600m, 13 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 24.0200m, 1, 15, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 15.6500m, 1, 16, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 21.0500m, 1, 17, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 16.1900m, 1, 18, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 20.7800m, 1, 19, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 23.2100m, 1, 20, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 20.2400m, 22, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 21.8600m, 23, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 19.4300m, 24, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 22.6700m, 2, 25, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 20.5100m, 2, 26, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 24.2900m, 2, 27, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Provider", "ProviderTransactionId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 25, 16.4600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 29, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0025", "Completed", null },
                    { 26, 20.2400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 30, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0026", "Completed", null }
                });

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1,
                column: "InitialReading",
                value: 53.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 2,
                column: "InitialReading",
                value: 39.40m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 3,
                column: "InitialReading",
                value: 70.80m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 4,
                column: "InitialReading",
                value: 44.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 5,
                column: "InitialReading",
                value: 33.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 6,
                column: "InitialReading",
                value: 14.80m);

            migrationBuilder.InsertData(
                table: "InvoiceItems",
                columns: new[] { "Id", "Amount", "CreatedAt", "Description", "InvoiceId", "Quantity", "TariffId", "UnitPrice", "UpdatedAt" },
                values: new object[,]
                {
                    { 61, 12.1500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 31, 9.00m, 1, 1.35m, null },
                    { 62, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 31, 1m, 1, 3.50m, null },
                    { 63, 15.6600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 32, 11.60m, 1, 1.35m, null },
                    { 64, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 32, 1m, 1, 3.50m, null },
                    { 65, 11.3400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 33, 8.40m, 1, 1.35m, null },
                    { 66, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 33, 1m, 1, 3.50m, null },
                    { 67, 16.4700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 34, 12.20m, 1, 1.35m, null },
                    { 68, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 34, 1m, 1, 3.50m, null },
                    { 69, 14.5800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 35, 10.80m, 1, 1.35m, null },
                    { 70, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 35, 1m, 1, 3.50m, null },
                    { 71, 15.6600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 36, 11.60m, 1, 1.35m, null },
                    { 72, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 36, 1m, 1, 3.50m, null },
                    { 73, 18.3600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 37, 13.60m, 1, 1.35m, null },
                    { 74, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 37, 1m, 1, 3.50m, null },
                    { 75, 14.3100m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 38, 10.60m, 1, 1.35m, null },
                    { 76, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 38, 1m, 1, 3.50m, null },
                    { 77, 18.0900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 39, 13.40m, 1, 1.35m, null },
                    { 78, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 39, 1m, 1, 3.50m, null },
                    { 79, 15.1200m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 40, 11.20m, 1, 1.35m, null },
                    { 80, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 40, 1m, 1, 3.50m, null },
                    { 81, 19.9800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 41, 14.80m, 1, 1.35m, null },
                    { 82, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 41, 1m, 1, 3.50m, null },
                    { 83, 12.9600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Potrosnja vode", 42, 9.60m, 1, 1.35m, null },
                    { 84, 3.50m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Fiksna naknada", 42, 1m, 1, 3.50m, null }
                });

            migrationBuilder.InsertData(
                table: "MeterReadings",
                columns: new[] { "Id", "ClientUuid", "CollectorId", "ConsumptionM3", "CreatedAt", "InvoiceId", "Note", "PhotoUrl", "PreviousReadingValue", "ReadingDate", "ReadingValue", "TariffId", "UpdatedAt", "VoidedAt", "WaterMeterId" },
                values: new object[,]
                {
                    { 31, "reading-wm0005-h03", 2, 9.00m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 31, "Redovno satno ocitanje.", null, 55.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 64.00m, 1, null, null, 5 },
                    { 32, "reading-wm0005-h04", 2, 11.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 32, "Redovno satno ocitanje.", null, 64.00m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 75.60m, 1, null, null, 5 },
                    { 33, "reading-wm0005-h05", 2, 8.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 33, "Redovno satno ocitanje.", null, 75.60m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 84.00m, 1, null, null, 5 },
                    { 34, "reading-wm0005-h06", 2, 12.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 34, "Redovno satno ocitanje.", null, 84.00m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 96.20m, 1, null, null, 5 },
                    { 35, "reading-wm0005-h07", 2, 10.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 35, "Redovno satno ocitanje.", null, 96.20m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 107.00m, 1, null, null, 5 },
                    { 36, "reading-wm0006-h01", 2, 11.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 36, "Redovno satno ocitanje.", null, 14.80m, new DateTime(2026, 6, 1, 6, 0, 0, 0, DateTimeKind.Utc), 26.40m, 1, null, null, 6 },
                    { 37, "reading-wm0006-h02", 2, 13.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 37, "Redovno satno ocitanje.", null, 26.40m, new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), 40.00m, 1, null, null, 6 },
                    { 38, "reading-wm0006-h03", 2, 10.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 38, "Redovno satno ocitanje.", null, 40.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 50.60m, 1, null, null, 6 },
                    { 39, "reading-wm0006-h04", 2, 13.40m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 39, "Redovno satno ocitanje.", null, 50.60m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 64.00m, 1, null, null, 6 },
                    { 40, "reading-wm0006-h05", 2, 11.20m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 40, "Redovno satno ocitanje.", null, 64.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 75.20m, 1, null, null, 6 },
                    { 41, "reading-wm0006-h06", 2, 14.80m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 41, "Redovno satno ocitanje.", null, 75.20m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 90.00m, 1, null, null, 6 },
                    { 42, "reading-wm0006-h07", 2, 9.60m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 42, "Redovno satno ocitanje.", null, 90.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 99.60m, 1, null, null, 6 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CreatedAt", "CustomerId", "InvoiceId", "PaidAt", "PaymentMethod", "Provider", "ProviderTransactionId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 27, 15.6500m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 31, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0027", "Completed", null },
                    { 28, 19.1600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 32, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0028", "Completed", null },
                    { 29, 14.8400m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 33, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0029", "Completed", null },
                    { 30, 19.9700m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 34, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0030", "Completed", null },
                    { 31, 18.0800m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, 35, new DateTime(2026, 6, 1, 14, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0031", "Completed", null },
                    { 32, 19.1600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 36, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0032", "Completed", null },
                    { 33, 21.8600m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 37, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0033", "Completed", null },
                    { 34, 17.8100m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 38, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), "BankTransfer", "Manual", "PAY-2026-0034", "Completed", null },
                    { 35, 21.5900m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 39, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), "Card", "Manual", "PAY-2026-0035", "Completed", null },
                    { 36, 18.6200m, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, 40, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), "Cash", "Manual", "PAY-2026-0036", "Completed", null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 61);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 62);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 63);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 64);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 65);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 66);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 67);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 68);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 69);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 70);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 71);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 72);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 73);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 74);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 75);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 76);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 77);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 78);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 79);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 80);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 81);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 82);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 83);

            migrationBuilder.DeleteData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 84);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 37);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 38);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 39);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 40);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 41);

            migrationBuilder.DeleteData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 42);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 37);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 38);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 39);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 40);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 41);

            migrationBuilder.DeleteData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 42);

            migrationBuilder.UpdateData(
                table: "ConsumptionAlertTypes",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Name", "NameDe", "NameEn" },
                values: new object[] { "Neuobičajen skok potrošnje", "Ungewöhnlicher Verbrauchsanstieg", "Unusual consumption spike" });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.4700m, 12.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 21.3300m, 15.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.0400m, 10.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 22.4100m, 16.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.1700m, 14.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 11.0700m, 8.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.3900m, 11.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.2300m, 9.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 10.2600m, 7.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.3100m, 10.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.5500m, 13.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.6900m, 9.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.2800m, 12.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.7100m, 14.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.7700m, 10.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 31,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.9300m, 11.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 33,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.1700m, 14.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 35,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 17.0100m, 12.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 37,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 20.7900m, 15.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 39,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 13.5000m, 10.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 41,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.1500m, 9.00m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 43,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.6600m, 11.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 45,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 11.3400m, 8.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 47,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 16.4700m, 12.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 49,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.5800m, 10.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 51,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 14.3100m, 10.60m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 53,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 18.0900m, 13.40m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 55,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 15.1200m, 11.20m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 57,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 19.9800m, 14.80m });

            migrationBuilder.UpdateData(
                table: "InvoiceItems",
                keyColumn: "Id",
                keyValue: 59,
                columns: new[] { "Amount", "Quantity" },
                values: new object[] { 12.9600m, 9.60m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 12.20m, 92.20m, 80.00m, 19.9700m, 19.9700m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 15.80m, 108.00m, 92.20m, 24.8300m, 24.8300m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 10.40m, 118.40m, 108.00m, 17.5400m, 17.5400m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 16.60m, 135.00m, 118.40m, 25.9100m, 25.9100m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 14.20m, 149.20m, 135.00m, "Issued", 22.6700m, 22.6700m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 8.20m, 68.20m, 60.00m, 14.5700m, 14.5700m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 11.40m, 79.60m, 68.20m, "Paid", 18.8900m, 18.8900m, 2 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 9.80m, 89.40m, 79.60m, 16.7300m, 16.7300m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 7.60m, 97.00m, 89.40m, 13.7600m, 13.7600m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.60m, 107.60m, 97.00m, "Issued", 17.8100m, 17.8100m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 13.00m, 108.00m, 95.00m, 21.0500m, 21.0500m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 9.40m, 117.40m, 108.00m, 16.1900m, 16.1900m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 12.80m, 130.20m, 117.40m, 20.7800m, 20.7800m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 14.60m, 144.80m, 130.20m, "Paid", 23.2100m, 23.2100m, 3 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Status", "Subtotal", "TotalAmount" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.20m, 155.00m, 144.80m, "Issued", 17.2700m, 17.2700m });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 11.80m, 81.80m, 2, 70.00m, 19.4300m, 19.4300m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 14.20m, 96.00m, 2, 81.80m, 22.6700m, 22.6700m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 12.60m, 108.60m, 2, 96.00m, 20.5100m, 20.5100m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 15.40m, 124.00m, 2, 108.60m, 24.2900m, 24.2900m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.00m, 134.00m, 2, 124.00m, "Issued", 17.0000m, 17.0000m, 4 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 9.00m, 64.00m, 2, 55.00m, "Paid", 15.6500m, 15.6500m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 11.60m, 75.60m, 64.00m, 19.1600m, 19.1600m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 8.40m, 84.00m, 75.60m, 14.8400m, 14.8400m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 12.20m, 96.20m, 84.00m, 19.9700m, 19.9700m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 10.80m, 107.00m, 96.20m, 18.0800m, 18.0800m, 5 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 7, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 10.60m, 50.60m, 3, 40.00m, 17.8100m, 17.8100m, 6 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 13.40m, 64.00m, 3, 50.60m, 21.5900m, 21.5900m, 6 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 11.20m, 75.20m, 3, 64.00m, "Paid", 18.6200m, 18.6200m, 6 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 14.80m, 90.00m, 3, 75.20m, "Issued", 23.4800m, 23.4800m, 6 });

            migrationBuilder.UpdateData(
                table: "Invoices",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "BillingPeriodFrom", "BillingPeriodTo", "ConsumptionM3", "CurrentReading", "CustomerId", "PreviousReading", "Status", "Subtotal", "TotalAmount", "WaterMeterId" },
                values: new object[] { new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 9.60m, 99.60m, 3, 90.00m, "Issued", 16.4600m, 16.4600m, 6 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 12.20m, 80.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 92.20m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 15.80m, 92.20m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 108.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 10.40m, 108.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 118.40m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 16.60m, 118.40m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 135.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { 14.20m, 135.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 149.20m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h01", 8.20m, 60.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 68.20m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0002-h02", 11.40m, 68.20m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 79.60m, 2 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h03", 9.80m, 79.60m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 89.40m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h04", 7.60m, 89.40m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 97.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0002-h05", 10.60m, 97.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 107.60m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h01", 13.00m, 95.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 108.00m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h02", 9.40m, 108.00m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 117.40m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h03", 12.80m, 117.40m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 130.20m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0003-h04", 14.60m, 130.20m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 144.80m, 3 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue" },
                values: new object[] { "reading-wm0003-h05", 10.20m, 144.80m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 155.00m });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h01", 2, 11.80m, 70.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 81.80m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h02", 2, 14.20m, 81.80m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 96.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h03", 2, 12.60m, 96.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 108.60m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h04", 2, 15.40m, 108.60m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 124.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0004-h05", 2, 10.00m, 124.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 134.00m, 4 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "ClientUuid", "CollectorId", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h01", 2, 9.00m, 55.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 64.00m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h02", 11.60m, 64.00m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 75.60m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h03", 8.40m, 75.60m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 84.00m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h04", 12.20m, 84.00m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 96.20m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 25,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0005-h05", 10.80m, 96.20m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 107.00m, 5 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 26,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0006-h01", 10.60m, 40.00m, new DateTime(2026, 6, 1, 8, 0, 0, 0, DateTimeKind.Utc), 50.60m, 6 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 27,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0006-h02", 13.40m, 50.60m, new DateTime(2026, 6, 1, 9, 0, 0, 0, DateTimeKind.Utc), 64.00m, 6 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 28,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0006-h03", 11.20m, 64.00m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc), 75.20m, 6 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 29,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0006-h04", 14.80m, 75.20m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc), 90.00m, 6 });

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 30,
                columns: new[] { "ClientUuid", "ConsumptionM3", "PreviousReadingValue", "ReadingDate", "ReadingValue", "WaterMeterId" },
                values: new object[] { "reading-wm0006-h05", 9.60m, 90.00m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc), 99.60m, 6 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 19.9700m, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 24.8300m, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 17.5400m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 25.9100m, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 14.5700m, 6, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 18.8900m, 7, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 16.7300m, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "Amount", "PaidAt" },
                values: new object[] { 13.7600m, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 21.0500m, 11 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 16.1900m, 12 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 20.7800m, 13 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "Amount", "InvoiceId" },
                values: new object[] { 23.2100m, 14 });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 19.4300m, 2, 16, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 22.6700m, 2, 17, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 15,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 20.5100m, 2, 18, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 16,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 24.2900m, 2, 19, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 17,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 15.6500m, 2, 21, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 18,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 19.1600m, 2, 22, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 19,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 14.8400m, 23, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 20,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 19.9700m, 24, new DateTime(2026, 6, 1, 13, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 21,
                columns: new[] { "Amount", "InvoiceId", "PaidAt" },
                values: new object[] { 18.0800m, 25, new DateTime(2026, 6, 1, 14, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 22,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 17.8100m, 3, 26, new DateTime(2026, 6, 1, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 23,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 21.5900m, 3, 27, new DateTime(2026, 6, 1, 11, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 24,
                columns: new[] { "Amount", "CustomerId", "InvoiceId", "PaidAt" },
                values: new object[] { 18.6200m, 3, 28, new DateTime(2026, 6, 1, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 1,
                column: "InitialReading",
                value: 80.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 2,
                column: "InitialReading",
                value: 60.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 3,
                column: "InitialReading",
                value: 95.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 4,
                column: "InitialReading",
                value: 70.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 5,
                column: "InitialReading",
                value: 55.00m);

            migrationBuilder.UpdateData(
                table: "WaterMeters",
                keyColumn: "Id",
                keyValue: 6,
                column: "InitialReading",
                value: 40.00m);
        }
    }
}
