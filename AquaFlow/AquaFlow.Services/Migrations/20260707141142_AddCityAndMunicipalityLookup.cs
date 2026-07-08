using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddCityAndMunicipalityLookup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Settlements_Name_City",
                table: "Settlements");

            migrationBuilder.DropColumn(
                name: "City",
                table: "Settlements");

            migrationBuilder.AddColumn<int>(
                name: "MunicipalityId",
                table: "Settlements",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Code = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Municipalities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Code = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Municipalities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Municipalities_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Cities",
                columns: new[] { "Id", "Code", "CreatedAt", "Name", "UpdatedAt" },
                values: new object[] { 1, "SA", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Sarajevo", null });

            migrationBuilder.UpdateData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "MunicipalityId", "Name" },
                values: new object[] { 1, "Bjelave" });

            migrationBuilder.UpdateData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "MunicipalityId", "Name", "PostalCode" },
                values: new object[] { 5, "Hrasnica", "71212" });

            migrationBuilder.InsertData(
                table: "Municipalities",
                columns: new[] { "Id", "CityId", "Code", "CreatedAt", "Name", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, 1, "SA-01", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Centar", null },
                    { 2, 1, "SA-02", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Novi Grad", null },
                    { 3, 1, "SA-03", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Novo Sarajevo", null },
                    { 4, 1, "SA-04", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Stari Grad", null },
                    { 5, 1, "SA-05", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Ilidza", null },
                    { 6, 1, "SA-06", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Vogosca", null },
                    { 7, 1, "SA-07", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Hadzici", null },
                    { 8, 1, "SA-08", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Ilijas", null },
                    { 9, 1, "SA-09", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Trnovo", null }
                });

            migrationBuilder.InsertData(
                table: "Settlements",
                columns: new[] { "Id", "CreatedAt", "MunicipalityId", "Name", "PostalCode", "UpdatedAt" },
                values: new object[,]
                {
                    { 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "Mejtas", "71000", null },
                    { 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "Kosevo", "71000", null },
                    { 5, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "Alipasino Polje", "71000", null },
                    { 6, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "Dobrinja", "71000", null },
                    { 7, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 2, "Otoka", "71000", null },
                    { 8, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, "Grbavica", "71000", null },
                    { 9, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, "Hrasno", "71000", null },
                    { 10, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3, "Pofalici", "71000", null },
                    { 11, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 4, "Bascarsija", "71000", null },
                    { 12, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 4, "Vratnik", "71000", null },
                    { 13, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5, "Sokolovic Kolonija", "71210", null },
                    { 14, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 5, "Otes", "71210", null },
                    { 15, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 6, "Semizovac", "71320", null },
                    { 16, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 6, "Kobilja Glava", "71320", null },
                    { 17, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 6, "Blagovac", "71320", null },
                    { 18, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 7, "Pazaric", "71240", null },
                    { 19, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 7, "Tarcin", "71240", null },
                    { 20, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 7, "Binjezevo", "71240", null },
                    { 21, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 8, "Podlugovi", "71380", null },
                    { 22, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 8, "Mrakovo", "71380", null },
                    { 23, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 9, "Sabici", "71223", null },
                    { 24, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 9, "Dejcici", "71223", null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Settlements_MunicipalityId_Name",
                table: "Settlements",
                columns: new[] { "MunicipalityId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_Code",
                table: "Cities",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_Name",
                table: "Cities",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Municipalities_CityId_Name",
                table: "Municipalities",
                columns: new[] { "CityId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Municipalities_Code",
                table: "Municipalities",
                column: "Code",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Settlements_Municipalities_MunicipalityId",
                table: "Settlements",
                column: "MunicipalityId",
                principalTable: "Municipalities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Settlements_Municipalities_MunicipalityId",
                table: "Settlements");

            migrationBuilder.DropTable(
                name: "Municipalities");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Settlements_MunicipalityId_Name",
                table: "Settlements");

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DropColumn(
                name: "MunicipalityId",
                table: "Settlements");

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "Settlements",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "City", "Name" },
                values: new object[] { "Sarajevo", "Centar" });

            migrationBuilder.UpdateData(
                table: "Settlements",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "City", "Name", "PostalCode" },
                values: new object[] { "Sarajevo", "Ilidza", "71210" });

            migrationBuilder.CreateIndex(
                name: "IX_Settlements_Name_City",
                table: "Settlements",
                columns: new[] { "Name", "City" },
                unique: true);
        }
    }
}
