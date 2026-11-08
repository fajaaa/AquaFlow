using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationAudienceLookup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "NotificationAudiences",
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
                    table.PrimaryKey("PK_NotificationAudiences", x => x.Id);
                    table.UniqueConstraint("AK_NotificationAudiences_Code", x => x.Code);
                });

            migrationBuilder.InsertData(
                table: "NotificationAudiences",
                columns: new[] { "Id", "Code", "CreatedAt", "IsActive", "IsSystem", "Name", "NameDe", "NameEn", "SortOrder", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "All", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Svi korisnici", "Alle Benutzer", "All users", 10, null },
                    { 2, "Customers", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Kupci", "Kunden", "Customers", 20, null },
                    { 3, "Collectors", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Inkasanti", "Ableser", "Collectors", 30, null },
                    { 4, "Direct", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), true, true, "Direktno - sistemske", "Direkt - System", "Direct - system", 40, null }
                });

            // The FK is by code: SQL Server requires the referencing column to have exactly the same
            // length as NotificationAudiences.Code (nvarchar(50)), so widen Audience from 40 first.
            migrationBuilder.AlterColumn<string>(
                name: "Audience",
                table: "Notifications",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(40)",
                oldMaxLength: 40);

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_Audience",
                table: "Notifications",
                column: "Audience");

            // Data safety: normalize legacy spellings to the canonical codes first.
            migrationBuilder.Sql("UPDATE [Notifications] SET [Audience] = 'All' WHERE LOWER([Audience]) = 'all' AND [Audience] <> 'All';");
            migrationBuilder.Sql("UPDATE [Notifications] SET [Audience] = 'Customers' WHERE LOWER([Audience]) IN ('customer', 'customers') AND [Audience] <> 'Customers';");
            migrationBuilder.Sql("UPDATE [Notifications] SET [Audience] = 'Collectors' WHERE LOWER([Audience]) IN ('collector', 'collectors') AND [Audience] <> 'Collectors';");
            migrationBuilder.Sql("UPDATE [Notifications] SET [Audience] = 'Direct' WHERE LOWER([Audience]) = 'direct' AND [Audience] <> 'Direct';");

            // Any value still missing from the codebook is inserted as a non-system row (Name = Code),
            // so AddForeignKey cannot fail and no business row has to change.
            migrationBuilder.Sql(@"
INSERT INTO [NotificationAudiences] ([Code], [Name], [NameEn], [NameDe], [SortOrder], [IsSystem], [IsActive], [CreatedAt], [UpdatedAt])
SELECT DISTINCT s.[Audience], s.[Audience], NULL, NULL, 1000, 0, 1, SYSUTCDATETIME(), NULL
FROM [Notifications] s
WHERE s.[Audience] IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM [NotificationAudiences] l WHERE l.[Code] = s.[Audience]);");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_NotificationAudiences_Audience",
                table: "Notifications",
                column: "Audience",
                principalTable: "NotificationAudiences",
                principalColumn: "Code",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_NotificationAudiences_Audience",
                table: "Notifications");

            migrationBuilder.DropTable(
                name: "NotificationAudiences");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_Audience",
                table: "Notifications");

            migrationBuilder.AlterColumn<string>(
                name: "Audience",
                table: "Notifications",
                type: "nvarchar(40)",
                maxLength: 40,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);
        }
    }
}
