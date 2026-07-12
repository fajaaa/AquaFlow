using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

// Pure photo-table CRUD against an already-trusted FaultReportId. Ownership/ownership-status
// gating (who may upload/view/delete against a given report) is the controller's
// responsibility, the same way FaultReportsController.GetById checks ownership before
// trusting the FaultReport row - this service only enforces that a photo belongs to the
// FaultReportId it is looked up under.
public interface IFaultReportPhotoService
{
    Task<FaultReportPhotoResponse> UploadAsync(int faultReportId, byte[] data, string contentType, string fileName);

    // Row count only - does not load photo blob data.
    Task<int> CountAsync(int faultReportId);

    Task<List<FaultReportPhotoResponse>> GetMetadataAsync(int faultReportId);

    // Throws KeyNotFoundException when no photo with photoId exists under faultReportId.
    Task<FaultReportPhotoFile> GetFileAsync(int faultReportId, int photoId);

    // Throws KeyNotFoundException when no photo with photoId exists under faultReportId.
    Task DeleteAsync(int faultReportId, int photoId);
}
