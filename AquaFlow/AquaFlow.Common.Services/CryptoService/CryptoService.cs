using System.Security.Cryptography;
using System.Text;

namespace AquaFlow.Common.Services.CryptoService;

public class CryptoService : ICryptoService
{
    public string GenerateSalt()
    {
        using var rng = RandomNumberGenerator.Create();
        byte[] saltBytes = new byte[16];
        rng.GetBytes(saltBytes);
        return Convert.ToBase64String(saltBytes);
    }

    public string GenerateHash(string password, string salt)
    {
        using var pbkdf2 = new Rfc2898DeriveBytes(
            password,
            Encoding.UTF8.GetBytes(salt),
            10000,
            HashAlgorithmName.SHA256);
        byte[] hash = pbkdf2.GetBytes(20);
        return Convert.ToBase64String(hash);
    }

    public bool Verify(string hash, string salt, string password)
    {
        var generated = GenerateHash(password, salt);

        // Constant-time comparison: a plain `hash == generated` short-circuits on the first differing
        // character, which leaks (via response timing) how much of the hash a guess matched. Comparing
        // the encoded bytes with FixedTimeEquals always inspects every byte. Working on the UTF-8 bytes
        // of the base64 strings keeps it robust against a malformed stored value (no decode to throw).
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(hash),
            Encoding.UTF8.GetBytes(generated));
    }
}
