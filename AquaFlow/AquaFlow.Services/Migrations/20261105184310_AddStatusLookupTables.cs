using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusLookupTables : Migration
    {
        // (codebook table, business table, FK column) - one entry per FK added below.
        private static readonly (string Lookup, string Source, string Column)[] LookupSources =
        {
            ("InvoiceStatuses", "Invoices", "Status"),
            ("InvoiceStatuses", "InvoiceStatusHistories", "NewStatus"),
            ("InvoiceStatuses", "InvoiceStatusHistories", "OldStatus"),
            ("PaymentStatuses", "Payments", "Status"),
            ("PaymentMethods", "Payments", "PaymentMethod"),
            ("FaultReportStatuses", "FaultReports", "Status"),
            ("FaultReportStatuses", "FaultStatusHistories", "NewStatus"),
            ("FaultReportStatuses", "FaultStatusHistories", "OldStatus"),
            ("WaterMeterRequestStatuses", "WaterMeterRequests", "Status"),
            ("WaterMeterRequestStatuses", "WaterMeterRequestStatusHistories", "NewStatus"),
            ("WaterMeterRequestStatuses", "WaterMeterRequestStatusHistories", "OldStatus"),
            ("WaterMeterStatuses", "WaterMeters", "Status"),
            ("SupportTicketStatuses", "SupportTickets", "Status"),
            ("NotificationTypes", "Notifications", "Type"),
            ("ConsumptionAlertTypes", "WaterConsumptionAlerts", "AlertType"),
        };

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "WaterMeters",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "WaterMeterRequestStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "WaterMeterRequestStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "WaterMeterRequests",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "AlertType",
                table: "WaterConsumptionAlerts",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(60)",
                oldMaxLength: 60);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "SupportTickets",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Payments",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "PaymentMethod",
                table: "Payments",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(40)",
                oldMaxLength: 40);

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "Notifications",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(40)",
                oldMaxLength: 40);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "InvoiceStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "InvoiceStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Invoices",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "FaultStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "FaultStatusHistories",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "FaultReports",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.CreateTable(
                name: "ConsumptionAlertTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConsumptionAlertTypes", x => x.Id);
                    table.UniqueConstraint("AK_ConsumptionAlertTypes_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "FaultReportStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FaultReportStatuses", x => x.Id);
                    table.UniqueConstraint("AK_FaultReportStatuses_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "InvoiceStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InvoiceStatuses", x => x.Id);
                    table.UniqueConstraint("AK_InvoiceStatuses_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "NotificationTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTypes", x => x.Id);
                    table.UniqueConstraint("AK_NotificationTypes_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "PaymentMethods",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentMethods", x => x.Id);
                    table.UniqueConstraint("AK_PaymentMethods_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "PaymentStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentStatuses", x => x.Id);
                    table.UniqueConstraint("AK_PaymentStatuses_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "SupportTicketStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportTicketStatuses", x => x.Id);
                    table.UniqueConstraint("AK_SupportTicketStatuses_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "WaterMeterRequestStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaterMeterRequestStatuses", x => x.Id);
                    table.UniqueConstraint("AK_WaterMeterRequestStatuses_Code", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "WaterMeterStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    NameDe = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsSystem = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaterMeterStatuses", x => x.Id);
                    table.UniqueConstraint("AK_WaterMeterStatuses_Code", x => x.Code);
                });

            migrationBuilder.InsertData(
                table: "ConsumptionAlertTypes",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[] { 1, "UnusualConsumptionSpike", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Neuobičajen skok potrošnje", "Ungewöhnlicher Verbrauchsanstieg", "Unusual consumption spike", 10, null });

            migrationBuilder.InsertData(
                table: "FaultReportStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "New", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Nova", "Neu", "New", 10, null },
                    { 2, "Assigned", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Dodijeljena", "Zugewiesen", "Assigned", 20, null },
                    { 3, "InProgress", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "U toku", "In Bearbeitung", "In progress", 30, null },
                    { 4, "Resolved", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Riješena", "Gelöst", "Resolved", 40, null }
                });

            migrationBuilder.InsertData(
                table: "InvoiceStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Issued", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Izdana", "Ausgestellt", "Issued", 10, null },
                    { 2, "Paid", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Plaćena", "Bezahlt", "Paid", 20, null },
                    { 3, "Cancelled", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Stornirana", "Storniert", "Cancelled", 30, null }
                });

            migrationBuilder.InsertData(
                table: "NotificationTypes",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Info", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Informacija", "Information", "Information", 10, null },
                    { 2, "Billing", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Naplata", "Abrechnung", "Billing", 20, null },
                    { 3, "Warning", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Upozorenje", "Warnung", "Warning", 30, null },
                    { 4, "PlannedWorks", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Planirani radovi", "Geplante Arbeiten", "Planned works", 40, null }
                });

            migrationBuilder.InsertData(
                table: "PaymentMethods",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Manual", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Ručno evidentirano", "Manuell erfasst", "Manual", 10, null },
                    { 2, "Online", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Online", "Online", "Online", 20, null },
                    { 3, "Cash", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Gotovina", "Bargeld", "Cash", 30, null },
                    { 4, "BankTransfer", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, false, "Bankovni transfer", "Banküberweisung", "Bank transfer", 40, null },
                    { 5, "Card", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, false, "Kartica", "Karte", "Card", 50, null }
                });

            migrationBuilder.InsertData(
                table: "PaymentStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Pending", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Na čekanju", "Ausstehend", "Pending", 10, null },
                    { 2, "Completed", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Završena", "Abgeschlossen", "Completed", 20, null },
                    { 3, "Failed", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Neuspješna", "Fehlgeschlagen", "Failed", 30, null },
                    { 4, "Refunded", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Refundirana", "Erstattet", "Refunded", 40, null }
                });

            migrationBuilder.InsertData(
                table: "Permissions",
                columns: new[] { "Id", "Code", "CreatedAt", "Description", "IsActive", "Module", "Name", "UpdatedAt" },
                values: new object[] { 25, "Codebooks.Manage", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Allows creating, updating, and deleting codebook values (statuses, payment methods, notification and alert types).", true, "Codebooks", "Manage codebooks", null });

            migrationBuilder.InsertData(
                table: "SupportTicketStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Open", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Otvoren", "Offen", "Open", 10, null },
                    { 2, "Closed", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Zatvoren", "Geschlossen", "Closed", 20, null }
                });

            migrationBuilder.InsertData(
                table: "WaterMeterRequestStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Pending", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Na čekanju", "Ausstehend", "Pending", 10, null },
                    { 2, "Assigned", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Dodijeljen", "Zugewiesen", "Assigned", 20, null },
                    { 3, "Registered", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Registrovan", "Registriert", "Registered", 30, null },
                    { 4, "Rejected", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Odbijen", "Abgelehnt", "Rejected", 40, null },
                    { 5, "Cancelled", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Otkazan", "Storniert", "Cancelled", 50, null }
                });

            migrationBuilder.InsertData(
                table: "WaterMeterStatuses",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Active", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Aktivan", "Aktiv", "Active", 10, null },
                    { 2, "Inactive", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Neaktivan", "Inaktiv", "Inactive", 20, null },
                    { 3, "Removed", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Uklonjen", "Entfernt", "Removed", 30, null }
                });

            migrationBuilder.InsertData(
                table: "UserRolePermissions",
                columns: new[] { "Id", "CreatedAt", "PermissionId", "UpdatedAt", "UserRoleId" },
                values: new object[] { 29, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 25, null, 1 });

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeters_Status",
                table: "WaterMeters",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequestStatusHistories_NewStatus",
                table: "WaterMeterRequestStatusHistories",
                column: "NewStatus");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequestStatusHistories_OldStatus",
                table: "WaterMeterRequestStatusHistories",
                column: "OldStatus");

            migrationBuilder.CreateIndex(
                name: "IX_WaterMeterRequests_Status",
                table: "WaterMeterRequests",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_WaterConsumptionAlerts_AlertType",
                table: "WaterConsumptionAlerts",
                column: "AlertType");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Status",
                table: "SupportTickets",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_PaymentMethod",
                table: "Payments",
                column: "PaymentMethod");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Status",
                table: "Payments",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_Type",
                table: "Notifications",
                column: "Type");

            migrationBuilder.CreateIndex(
                name: "IX_InvoiceStatusHistories_NewStatus",
                table: "InvoiceStatusHistories",
                column: "NewStatus");

            migrationBuilder.CreateIndex(
                name: "IX_InvoiceStatusHistories_OldStatus",
                table: "InvoiceStatusHistories",
                column: "OldStatus");

            migrationBuilder.CreateIndex(
                name: "IX_Invoices_Status",
                table: "Invoices",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_FaultStatusHistories_NewStatus",
                table: "FaultStatusHistories",
                column: "NewStatus");

            migrationBuilder.CreateIndex(
                name: "IX_FaultStatusHistories_OldStatus",
                table: "FaultStatusHistories",
                column: "OldStatus");

            migrationBuilder.CreateIndex(
                name: "IX_FaultReports_Status",
                table: "FaultReports",
                column: "Status");

            // Data safety: an existing database may hold values outside the seeded codebooks
            // (older demo data, hand-edited rows). Before the FKs are added, every distinct value
            // still missing from its codebook is inserted as a non-system row (Name = Code), so
            // AddForeignKey cannot fail and no business row has to change.
            foreach (var (lookupTable, sourceTable, sourceColumn) in LookupSources)
            {
                migrationBuilder.Sql($@"
INSERT INTO [{lookupTable}] ([Code], [Name], [NameEn], [NameDe], [SortOrder], [IsSystem], [IsActive], [CreatedAt], [UpdatedAt])
SELECT DISTINCT s.[{sourceColumn}], s.[{sourceColumn}], NULL, NULL, 1000, 0, 1, SYSUTCDATETIME(), NULL
FROM [{sourceTable}] s
WHERE s.[{sourceColumn}] IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM [{lookupTable}] l WHERE l.[Code] = s.[{sourceColumn}]);");
            }

            migrationBuilder.AddForeignKey(
                name: "FK_FaultReports_FaultReportStatuses_Status",
                table: "FaultReports",
                column: "Status",
                principalTable: "FaultReportStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_FaultStatusHistories_FaultReportStatuses_NewStatus",
                table: "FaultStatusHistories",
                column: "NewStatus",
                principalTable: "FaultReportStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_FaultStatusHistories_FaultReportStatuses_OldStatus",
                table: "FaultStatusHistories",
                column: "OldStatus",
                principalTable: "FaultReportStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Invoices_InvoiceStatuses_Status",
                table: "Invoices",
                column: "Status",
                principalTable: "InvoiceStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_InvoiceStatusHistories_InvoiceStatuses_NewStatus",
                table: "InvoiceStatusHistories",
                column: "NewStatus",
                principalTable: "InvoiceStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_InvoiceStatusHistories_InvoiceStatuses_OldStatus",
                table: "InvoiceStatusHistories",
                column: "OldStatus",
                principalTable: "InvoiceStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_NotificationTypes_Type",
                table: "Notifications",
                column: "Type",
                principalTable: "NotificationTypes",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_PaymentMethods_PaymentMethod",
                table: "Payments",
                column: "PaymentMethod",
                principalTable: "PaymentMethods",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_PaymentStatuses_Status",
                table: "Payments",
                column: "Status",
                principalTable: "PaymentStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_SupportTickets_SupportTicketStatuses_Status",
                table: "SupportTickets",
                column: "Status",
                principalTable: "SupportTicketStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterConsumptionAlerts_ConsumptionAlertTypes_AlertType",
                table: "WaterConsumptionAlerts",
                column: "AlertType",
                principalTable: "ConsumptionAlertTypes",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeterRequests_WaterMeterRequestStatuses_Status",
                table: "WaterMeterRequests",
                column: "Status",
                principalTable: "WaterMeterRequestStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeterRequestStatusHistories_WaterMeterRequestStatuses_NewStatus",
                table: "WaterMeterRequestStatusHistories",
                column: "NewStatus",
                principalTable: "WaterMeterRequestStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeterRequestStatusHistories_WaterMeterRequestStatuses_OldStatus",
                table: "WaterMeterRequestStatusHistories",
                column: "OldStatus",
                principalTable: "WaterMeterRequestStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WaterMeters_WaterMeterStatuses_Status",
                table: "WaterMeters",
                column: "Status",
                principalTable: "WaterMeterStatuses",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FaultReports_FaultReportStatuses_Status",
                table: "FaultReports");

            migrationBuilder.DropForeignKey(
                name: "FK_FaultStatusHistories_FaultReportStatuses_NewStatus",
                table: "FaultStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_FaultStatusHistories_FaultReportStatuses_OldStatus",
                table: "FaultStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_Invoices_InvoiceStatuses_Status",
                table: "Invoices");

            migrationBuilder.DropForeignKey(
                name: "FK_InvoiceStatusHistories_InvoiceStatuses_NewStatus",
                table: "InvoiceStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_InvoiceStatusHistories_InvoiceStatuses_OldStatus",
                table: "InvoiceStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_NotificationTypes_Type",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_PaymentMethods_PaymentMethod",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_PaymentStatuses_Status",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_SupportTickets_SupportTicketStatuses_Status",
                table: "SupportTickets");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterConsumptionAlerts_ConsumptionAlertTypes_AlertType",
                table: "WaterConsumptionAlerts");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeterRequests_WaterMeterRequestStatuses_Status",
                table: "WaterMeterRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeterRequestStatusHistories_WaterMeterRequestStatuses_NewStatus",
                table: "WaterMeterRequestStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeterRequestStatusHistories_WaterMeterRequestStatuses_OldStatus",
                table: "WaterMeterRequestStatusHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_WaterMeters_WaterMeterStatuses_Status",
                table: "WaterMeters");

            migrationBuilder.DropTable(
                name: "ConsumptionAlertTypes");

            migrationBuilder.DropTable(
                name: "FaultReportStatuses");

            migrationBuilder.DropTable(
                name: "InvoiceStatuses");

            migrationBuilder.DropTable(
                name: "NotificationTypes");

            migrationBuilder.DropTable(
                name: "PaymentMethods");

            migrationBuilder.DropTable(
                name: "PaymentStatuses");

            migrationBuilder.DropTable(
                name: "SupportTicketStatuses");

            migrationBuilder.DropTable(
                name: "WaterMeterRequestStatuses");

            migrationBuilder.DropTable(
                name: "WaterMeterStatuses");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeters_Status",
                table: "WaterMeters");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeterRequestStatusHistories_NewStatus",
                table: "WaterMeterRequestStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeterRequestStatusHistories_OldStatus",
                table: "WaterMeterRequestStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_WaterMeterRequests_Status",
                table: "WaterMeterRequests");

            migrationBuilder.DropIndex(
                name: "IX_WaterConsumptionAlerts_AlertType",
                table: "WaterConsumptionAlerts");

            migrationBuilder.DropIndex(
                name: "IX_SupportTickets_Status",
                table: "SupportTickets");

            migrationBuilder.DropIndex(
                name: "IX_Payments_PaymentMethod",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_Status",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_Type",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_InvoiceStatusHistories_NewStatus",
                table: "InvoiceStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_InvoiceStatusHistories_OldStatus",
                table: "InvoiceStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_Invoices_Status",
                table: "Invoices");

            migrationBuilder.DropIndex(
                name: "IX_FaultStatusHistories_NewStatus",
                table: "FaultStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_FaultStatusHistories_OldStatus",
                table: "FaultStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_FaultReports_Status",
                table: "FaultReports");

            migrationBuilder.DeleteData(
                table: "UserRolePermissions",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "Permissions",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "WaterMeters",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "WaterMeterRequestStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "WaterMeterRequestStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "WaterMeterRequests",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "AlertType",
                table: "WaterConsumptionAlerts",
                type: "nvarchar(60)",
                maxLength: 60,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "SupportTickets",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Payments",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "PaymentMethod",
                table: "Payments",
                type: "nvarchar(40)",
                maxLength: 40,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "Notifications",
                type: "nvarchar(40)",
                maxLength: 40,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "InvoiceStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "InvoiceStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Invoices",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "OldStatus",
                table: "FaultStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "NewStatus",
                table: "FaultStatusHistories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "FaultReports",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);
        }
    }
}
