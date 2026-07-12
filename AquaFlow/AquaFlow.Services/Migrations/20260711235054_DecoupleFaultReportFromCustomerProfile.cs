using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class DecoupleFaultReportFromCustomerProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "CustomerId",
                table: "FaultReports",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<string>(
                name: "HouseNumber",
                table: "FaultReports",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Street",
                table: "FaultReports",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.UpdateData(
                table: "FaultReports",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "HouseNumber", "Street" },
                values: new object[] { null, null });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HouseNumber",
                table: "FaultReports");

            migrationBuilder.DropColumn(
                name: "Street",
                table: "FaultReports");

            migrationBuilder.AlterColumn<int>(
                name: "CustomerId",
                table: "FaultReports",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);
        }
    }
}
