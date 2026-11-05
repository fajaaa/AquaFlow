namespace AquaFlow.Services;

// One already-validated photo for a new fault report (controller ran ImageUploadHelper first);
// ContentType is the one derived from the file's signature, not the client's claim.
public record FaultReportPhotoUpload(byte[] Data, string ContentType, string FileName);
