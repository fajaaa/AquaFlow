namespace AquaFlow.Services;

// One already-validated photo for a new support ticket message: the controller reads and checks
// every uploaded file (ImageUploadHelper - size, whitelist, magic bytes) into this shape first, so
// the service receives only good data and can store the message and all of its photos in a single
// SaveChanges. ContentType is the one derived from the file's signature, not the client's claim.
public record SupportTicketPhotoUpload(byte[] Data, string ContentType, string FileName);
