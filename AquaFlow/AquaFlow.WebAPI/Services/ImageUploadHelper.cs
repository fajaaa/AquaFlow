using AquaFlow.Model.Exceptions;

namespace AquaFlow.WebAPI.Services;

// Shared upload-image validation for the photo endpoints (FaultReportsController and
// SupportTicketsController). Enforces the 5MB size cap and the JPEG/PNG/WEBP whitelist, and -
// because a caller can label arbitrary bytes "image/png" - sniffs the actual magic bytes and
// returns the content type derived from the signature rather than the client's claim. Kept as a
// stateless static helper so both controllers share one copy of the limits, signatures, and error
// messages (they were previously duplicated inside FaultReportsController).
public static class ImageUploadHelper
{
    public const long MaxPhotoSizeBytes = 5 * 1024 * 1024;

    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/png",
        "image/webp"
    };

    private static readonly byte[] JpegSignature = { 0xFF, 0xD8, 0xFF };
    private static readonly byte[] PngSignature = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

    // Validates one uploaded image (non-empty, declared type whitelisted, size within the cap),
    // reads its bytes, verifies they match a known image signature, and returns the bytes together
    // with the content type derived from that signature. Throws ClientException (-> 400 via the
    // global ExceptionFilter) on any failure. The size cap is checked against the declared length so
    // an oversized upload is rejected before its bytes are ever read.
    public static async Task<(byte[] Data, string ContentType)> ReadValidatedImageAsync(IFormFile? file)
    {
        if (file is null || file.Length == 0)
        {
            throw new ClientException("A photo file is required.");
        }

        if (!AllowedContentTypes.Contains(file.ContentType))
        {
            throw new ClientException("Only JPEG, PNG, or WEBP images are allowed.");
        }

        if (file.Length > MaxPhotoSizeBytes)
        {
            throw new ClientException("Photo exceeds the 5MB size limit.");
        }

        using var buffer = new MemoryStream();
        await file.CopyToAsync(buffer);
        var data = buffer.ToArray();

        // file.ContentType is client-declared and already checked against the whitelist above, but a
        // caller can label arbitrary bytes "image/png". Sniff the actual bytes against each format's
        // magic-byte signature as an additional layer, and store/serve the type derived from the
        // signature rather than the client's claim.
        var detectedContentType = DetectImageContentType(data);
        if (detectedContentType is null)
        {
            throw new ClientException("Uploaded file is not a valid JPEG, PNG, or WEBP image.");
        }

        return (data, detectedContentType);
    }

    private static string? DetectImageContentType(byte[] data)
    {
        if (StartsWith(data, JpegSignature))
        {
            return "image/jpeg";
        }

        if (StartsWith(data, PngSignature))
        {
            return "image/png";
        }

        if (IsWebP(data))
        {
            return "image/webp";
        }

        return null;
    }

    private static bool IsWebP(byte[] data)
    {
        // RIFF <4-byte size> WEBP
        return data.Length >= 12
            && data[0] == (byte)'R' && data[1] == (byte)'I' && data[2] == (byte)'F' && data[3] == (byte)'F'
            && data[8] == (byte)'W' && data[9] == (byte)'E' && data[10] == (byte)'B' && data[11] == (byte)'P';
    }

    private static bool StartsWith(byte[] data, byte[] signature)
    {
        if (data.Length < signature.Length)
        {
            return false;
        }

        for (var i = 0; i < signature.Length; i++)
        {
            if (data[i] != signature[i])
            {
                return false;
            }
        }

        return true;
    }
}
