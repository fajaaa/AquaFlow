using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AquaFlow.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddSupportTicketLastMessageFromStaff : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "LastMessageFromStaff",
                table: "SupportTickets",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Backfill from each ticket's actual newest message so existing threads report the
            // correct value instead of defaulting every row to "awaiting reply".
            migrationBuilder.Sql(@"
                UPDATE st
                SET st.LastMessageFromStaff = latest.IsFromStaff
                FROM SupportTickets st
                CROSS APPLY (
                    SELECT TOP 1 m.IsFromStaff
                    FROM SupportTicketMessages m
                    WHERE m.SupportTicketId = st.Id
                    ORDER BY m.CreatedAt DESC, m.Id DESC
                ) latest;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastMessageFromStaff",
                table: "SupportTickets");
        }
    }
}
