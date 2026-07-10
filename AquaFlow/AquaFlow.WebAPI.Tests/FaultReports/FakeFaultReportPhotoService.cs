using AquaFlow.Model.Responses;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.FaultReports;

// Hand-written stand-in for IFaultReportPhotoService so controller tests can drive the
// photo sub-routes without a database. Storage is a simple in-memory list; ownership/status
// gating stays entirely in FaultReportsController, so this fake only enforces that a photo
// belongs to the FaultReportId it was uploaded under - same contract as the real service.
public class FakeFaultReportPhotoService : IFaultReportPhotoService
{
    private readonly List<(int FaultReportId, FaultReportPhotoResponse Response, byte[] Data)> _rows = new();
    private int _nextId = 1;

    public byte[]? LastUploadedData { get; private set; }

    public Task<FaultReportPhotoResponse> UploadAsync(int faultReportId, byte[] data, string contentType, string fileName)
    {
        LastUploadedData = data;
        var response = new FaultReportPhotoResponse
        {
            Id = _nextId++,
            FileName = fileName,
            ContentType = contentType,
            SizeBytes = data.LongLength,
            CreatedAt = DateTime.UtcNow
        };
        _rows.Add((faultReportId, response, data));
        return Task.FromResult(response);
    }

    public Task<List<FaultReportPhotoResponse>> GetMetadataAsync(int faultReportId)
    {
        var items = _rows.Where(row => row.FaultReportId == faultReportId).Select(row => row.Response).ToList();
        return Task.FromResult(items);
    }

    public Task<FaultReportPhotoFile> GetFileAsync(int faultReportId, int photoId)
    {
        var row = Find(faultReportId, photoId);
        return Task.FromResult(new FaultReportPhotoFile
        {
            Data = row.Data,
            ContentType = row.Response.ContentType,
            FileName = row.Response.FileName
        });
    }

    public Task DeleteAsync(int faultReportId, int photoId)
    {
        var row = Find(faultReportId, photoId);
        _rows.Remove(row);
        return Task.CompletedTask;
    }

    private (int FaultReportId, FaultReportPhotoResponse Response, byte[] Data) Find(int faultReportId, int photoId)
    {
        var index = _rows.FindIndex(row => row.FaultReportId == faultReportId && row.Response.Id == photoId);
        if (index < 0)
        {
            throw new KeyNotFoundException();
        }

        return _rows[index];
    }
}
