namespace AquaFlow.Services;

// Raw photo bytes for a download response. Kept separate from FaultReportPhotoResponse
// (the API metadata contract) so the byte payload never accidentally rides along with
// a metadata listing.
public class FaultReportPhotoFile
{
    public byte[] Data { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
}
