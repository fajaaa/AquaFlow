namespace AquaFlow.Common.Services.CryptoService;

public interface ICryptoService
{
    string GenerateSalt();
    string GenerateHash(string password, string salt);
    bool Verify(string hash, string salt, string password);
}
