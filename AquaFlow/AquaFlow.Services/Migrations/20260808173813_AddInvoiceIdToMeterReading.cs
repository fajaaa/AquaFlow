using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddInvoiceIdToMeterReading : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "InvoiceId",
                table: "MeterReadings",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "MeterReadings",
                keyColumn: "Id",
                keyValue: 1,
                column: "InvoiceId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_MeterReadings_InvoiceId",
                table: "MeterReadings",
                column: "InvoiceId");

            migrationBuilder.AddForeignKey(
                name: "FK_MeterReadings_Invoices_InvoiceId",
                table: "MeterReadings",
                column: "InvoiceId",
                principalTable: "Invoices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MeterReadings_Invoices_InvoiceId",
                table: "MeterReadings");

            migrationBuilder.DropIndex(
                name: "IX_MeterReadings_InvoiceId",
                table: "MeterReadings");

            migrationBuilder.DropColumn(
                name: "InvoiceId",
                table: "MeterReadings");
        }
    }
}
