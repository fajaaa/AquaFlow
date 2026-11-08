namespace AquaFlow.WebAPI.Services.AccessManager;

public static class ClaimNames
{
    public const string Id = "Id";
    public const string Email = "Email";
    public const string UserRole = "UserRole";
    public const string IsActive = "IsActive";
    public const string Permission = "Permission";

    // User.SecurityStamp at issue time; checked on every request (OnTokenValidated in Program.cs).
    public const string SecurityStamp = "SecurityStamp";
}
