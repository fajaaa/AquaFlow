using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class FaultReportPhotoService : IFaultReportPhotoService
{
    private readonly AquaFlowDbContext _dbContext;

    public FaultReportPhotoService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<FaultReportPhotoResponse> UploadAsync(int faultReportId, byte[] data, string contentType, string fileName)
    {
        var photo = new FaultReportPhoto
        {
            FaultReportId = faultReportId,
            Data = data,
            ContentType = contentType,
            FileName = fileName,
            SizeBytes = data.LongLength
        };

        _dbContext.FaultReportPhotos.Add(photo);
        await _dbContext.SaveChangesAsync();

        return ToResponse(photo);
    }

    public async Task<List<FaultReportPhotoResponse>> GetMetadataAsync(int faultReportId)
    {
        return await _dbContext.FaultReportPhotos
            .Where(photo => photo.FaultReportId == faultReportId)
            .OrderBy(photo => photo.CreatedAt)
            .Select(photo => new FaultReportPhotoResponse
            {
                Id = photo.Id,
                FileName = photo.FileName,
                ContentType = photo.ContentType,
                SizeBytes = photo.SizeBytes,
                CreatedAt = photo.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<FaultReportPhotoFile> GetFileAsync(int faultReportId, int photoId)
    {
        var photo = await FindAsync(faultReportId, photoId);

        return new FaultReportPhotoFile
        {
            Data = photo.Data,
            ContentType = photo.ContentType,
            FileName = photo.FileName
        };
    }

    public async Task DeleteAsync(int faultReportId, int photoId)
    {
        var photo = await FindAsync(faultReportId, photoId);

        _dbContext.FaultReportPhotos.Remove(photo);
        await _dbContext.SaveChangesAsync();
    }

    private async Task<FaultReportPhoto> FindAsync(int faultReportId, int photoId)
    {
        var photo = await _dbContext.FaultReportPhotos
            .FirstOrDefaultAsync(row => row.Id == photoId && row.FaultReportId == faultReportId);

        if (photo is null)
        {
            throw new KeyNotFoundException();
        }

        return photo;
    }

    private static FaultReportPhotoResponse ToResponse(FaultReportPhoto photo)
    {
        return new FaultReportPhotoResponse
        {
            Id = photo.Id,
            FileName = photo.FileName,
            ContentType = photo.ContentType,
            SizeBytes = photo.SizeBytes,
            CreatedAt = photo.CreatedAt
        };
    }
}
