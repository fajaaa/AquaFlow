using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class NotificationImageService : INotificationImageService
{
    private readonly AquaFlowDbContext _dbContext;

    public NotificationImageService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<NotificationImageResponse> UploadAsync(int notificationId, byte[] data, string contentType, string fileName)
    {
        var image = new NotificationImage
        {
            NotificationId = notificationId,
            Data = data,
            ContentType = contentType,
            FileName = fileName,
            SizeBytes = data.LongLength
        };

        _dbContext.NotificationImages.Add(image);
        await _dbContext.SaveChangesAsync();

        return ToResponse(image);
    }

    public Task<int> CountAsync(int notificationId)
    {
        return _dbContext.NotificationImages
            .Where(image => image.NotificationId == notificationId)
            .CountAsync();
    }

    public async Task<List<NotificationImageResponse>> GetMetadataAsync(int notificationId)
    {
        return await _dbContext.NotificationImages
            .Where(image => image.NotificationId == notificationId)
            .OrderBy(image => image.CreatedAt)
            .Select(image => new NotificationImageResponse
            {
                Id = image.Id,
                FileName = image.FileName,
                ContentType = image.ContentType,
                SizeBytes = image.SizeBytes,
                CreatedAt = image.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<NotificationImageFile> GetFileAsync(int notificationId, int imageId)
    {
        var image = await FindAsync(notificationId, imageId);

        return new NotificationImageFile
        {
            Data = image.Data,
            ContentType = image.ContentType,
            FileName = image.FileName
        };
    }

    public async Task DeleteAsync(int notificationId, int imageId)
    {
        var image = await FindAsync(notificationId, imageId);

        _dbContext.NotificationImages.Remove(image);
        await _dbContext.SaveChangesAsync();
    }

    private async Task<NotificationImage> FindAsync(int notificationId, int imageId)
    {
        var image = await _dbContext.NotificationImages
            .FirstOrDefaultAsync(row => row.Id == imageId && row.NotificationId == notificationId);

        if (image is null)
        {
            throw new KeyNotFoundException();
        }

        return image;
    }

    private static NotificationImageResponse ToResponse(NotificationImage image)
    {
        return new NotificationImageResponse
        {
            Id = image.Id,
            FileName = image.FileName,
            ContentType = image.ContentType,
            SizeBytes = image.SizeBytes,
            CreatedAt = image.CreatedAt
        };
    }
}
