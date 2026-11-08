using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddUserSecurityStamp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Hand-edited: the scaffolded defaultValue "" would give every existing user the SAME
            // empty stamp, and a token carrying an empty stamp is always rejected - existing users
            // could log in but never use the API. A NOT NULL column added with a default fills
            // existing rows with that default evaluated per row, so NEWID() backfills a unique
            // value (same 32-char lower-case hex shape as SecurityStampService.NewStamp). The
            // seeded users get their fixed values right after (UpdateData below). The DB default
            // constraint stays but is unused: the app always supplies the value on insert; it is
            // not in the EF model, which is fine - EF diffs the model, not the database.
            migrationBuilder.AddColumn<string>(
                name: "SecurityStamp",
                table: "Users",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: false,
                defaultValueSql: "LOWER(REPLACE(CONVERT(nvarchar(36), NEWID()), '-', ''))");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000001");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000002");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 3,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000003");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 4,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000004");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 5,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000005");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 6,
                column: "SecurityStamp",
                value: "seedsecuritystamp000000000000006");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SecurityStamp",
                table: "Users");
        }
    }
}
