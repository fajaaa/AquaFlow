using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.FaultReports;

public class FaultReportPhotosControllerTests
{
    private const string ManagePermission = "FaultReports.Manage";
    private const string CustomerRole = "Customer";
    private const string CollectorRole = "Collector";
    private const string AdminRole = "Admin";
    private static readonly byte[] PngSignatureBytes = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

    [Fact]
    public async Task UploadPhoto_OwnReport_ReturnsCreatedWithMetadataOnly()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF }, "image/jpeg", "leak.jpg");

        var result = await controller.UploadPhoto(1, file);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<FaultReportPhotoResponse>(created.Value);
        Assert.Equal("leak.jpg", response.FileName);
        Assert.Equal("image/jpeg", response.ContentType);
        Assert.Equal(3, response.SizeBytes);
    }

    [Fact]
    public async Task UploadPhoto_OtherCustomersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/jpeg", "leak.jpg");

        var result = await controller.UploadPhoto(1, file);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task UploadPhoto_ManagePermissionHolder_CanUploadToAnyReport()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(PngSignatureBytes, "image/png", "leak.png");

        var result = await controller.UploadPhoto(1, file);

        Assert.IsType<CreatedAtActionResult>(result.Result);
    }

    [Fact]
    public async Task UploadPhoto_EmptyFile_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(Array.Empty<byte>(), "image/jpeg", "empty.jpg");

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
    }

    [Fact]
    public async Task UploadPhoto_DisallowedContentType_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "application/pdf", "doc.pdf");

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
    }

    [Fact]
    public async Task UploadPhoto_ExceedsSizeLimit_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        // Declared Length exceeds 5MB; the underlying stream content is irrelevant since
        // validation must reject before ever reading/copying the bytes.
        var file = CreateFormFile(new byte[] { 1 }, "image/jpeg", "big.jpg", declaredLength: 5 * 1024 * 1024 + 1);

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
    }

    [Fact]
    public async Task UploadPhoto_SixthPhoto_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out var photoService);
        for (var i = 0; i < 5; i++)
        {
            await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", $"{i}.jpg");
        }

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/jpeg", "sixth.jpg");

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
    }

    [Fact]
    public async Task UploadPhoto_CustomerOnNonNewReport_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "InProgress" }],
            out _);

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/jpeg", "leak.jpg");

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
    }

    [Fact]
    public async Task UploadPhoto_ManagePermissionHolder_CanUploadRegardlessOfStatus()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "InProgress" }],
            out _);

        var file = CreateFormFile(PngSignatureBytes, "image/png", "leak.png");

        var result = await controller.UploadPhoto(1, file);

        Assert.IsType<CreatedAtActionResult>(result.Result);
    }

    // The client's declared Content-Type is not trustworthy on its own: a caller can label
    // arbitrary bytes "image/png". Magic-byte sniffing must reject content that doesn't match
    // any allowed image signature even though the declared type passes the whitelist check.
    [Fact]
    public async Task UploadPhoto_ContentDoesNotMatchDeclaredContentType_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(System.Text.Encoding.UTF8.GetBytes("not a real image"), "image/png", "fake.png");

        var exception = await Assert.ThrowsAsync<ClientException>(() => controller.UploadPhoto(1, file));
        Assert.Equal("Uploaded file is not a valid JPEG, PNG, or WEBP image.", exception.Message);
    }

    [Fact]
    public async Task GetPhotos_OwnReport_ReturnsMetadataOnly()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out var photoService);
        await photoService.UploadAsync(1, new byte[] { 1, 2, 3 }, "image/jpeg", "leak.jpg");

        var result = await controller.GetPhotos(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var items = Assert.IsAssignableFrom<List<FaultReportPhotoResponse>>(ok.Value);
        var item = Assert.Single(items);
        Assert.Equal("leak.jpg", item.FileName);
    }

    [Fact]
    public async Task GetPhotos_OtherCustomersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out _);

        var result = await controller.GetPhotos(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetPhoto_OwnReport_ReturnsRawBytes()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/jpeg", "leak.jpg");

        var result = await controller.GetPhoto(1, uploaded.Id);

        var fileResult = Assert.IsType<FileContentResult>(result);
        Assert.Equal(new byte[] { 9, 8, 7 }, fileResult.FileContents);
        Assert.Equal("image/jpeg", fileResult.ContentType);
    }

    [Fact]
    public async Task GetPhoto_OtherCustomersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/jpeg", "leak.jpg");

        var result = await controller.GetPhoto(1, uploaded.Id);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetPhoto_UnknownReportId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var result = await controller.GetPhoto(999, 1);

        Assert.IsType<NotFoundResult>(result);
    }

    // Pins that a FaultReports.Manage holder - who otherwise skips the ownership comparison
    // entirely - still gets a 404 (not a crash) when the report id itself doesn't exist.
    [Fact]
    public async Task GetPhoto_ManagePermissionHolder_UnknownReportId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out _);

        var result = await controller.GetPhoto(999, 1);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetPhoto_UnknownPhotoId_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var result = await controller.GetPhoto(1, 999);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task DeletePhoto_OwnerWhileStatusNew_Succeeds()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        var result = await controller.DeletePhoto(1, uploaded.Id);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeletePhoto_OwnerWhileStatusNotNew_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "InProgress" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        await Assert.ThrowsAsync<ClientException>(() => controller.DeletePhoto(1, uploaded.Id));
    }

    [Fact]
    public async Task DeletePhoto_ManagePermissionHolder_CanDeleteRegardlessOfStatus()
    {
        var controller = CreateController(
            BuildUser(userId: 99, role: AdminRole, permissions: [ManagePermission]),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "InProgress" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        var result = await controller.DeletePhoto(1, uploaded.Id);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeletePhoto_OtherCustomersReport_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 20, Title = "Leak", Status = "New" }],
            out var photoService);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        var result = await controller.DeletePhoto(1, uploaded.Id);

        Assert.IsType<NotFoundResult>(result);
    }

    // The assigned collector gets READ access to the photos (list + bytes) so they can see the
    // customer's evidence on site, but upload/delete stay owner-while-New-or-Manage only.
    [Fact]
    public async Task GetPhotos_AssignedCollector_ReturnsOk()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 7 }],
            out var photoService,
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);
        await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        var result = await controller.GetPhotos(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var photos = Assert.IsType<List<FaultReportPhotoResponse>>(ok.Value);
        Assert.Single(photos);
    }

    [Fact]
    public async Task GetPhoto_AssignedCollector_ReturnsBytes()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 7 }],
            out var photoService,
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1, 2, 3 }, "image/jpeg", "leak.jpg");

        var result = await controller.GetPhoto(1, uploaded.Id);

        var file = Assert.IsType<FileContentResult>(result);
        Assert.Equal(new byte[] { 1, 2, 3 }, file.FileContents);
    }

    [Fact]
    public async Task GetPhotos_UnassignedCollector_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 8 }],
            out _,
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var result = await controller.GetPhotos(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task UploadPhoto_AssignedCollector_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 7 }],
            out _,
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);

        var file = CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF }, "image/jpeg", "leak.jpg");

        var result = await controller.UploadPhoto(1, file);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task DeletePhoto_AssignedCollector_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 5, role: CollectorRole, permissions: []),
            profiles: [],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "Assigned", AssignedCollectorId = 7 }],
            out var photoService,
            collectorProfiles: [new CollectorProfileResponse { Id = 7, UserId = 5 }]);
        var uploaded = await photoService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "leak.jpg");

        var result = await controller.DeletePhoto(1, uploaded.Id);

        Assert.IsType<NotFoundResult>(result);
    }

    private static FaultReportsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<FaultReportResponse> reports,
        out FakeFaultReportPhotoService photoService,
        IEnumerable<CollectorProfileResponse>? collectorProfiles = null)
    {
        var faultReportService = new FakeFaultReportCrudService(reports);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        var collectorProfileService = new FakeCollectorProfileCrudService(collectorProfiles ?? []);
        var waterMeterService = new FakeWaterMeterCrudService([]);
        photoService = new FakeFaultReportPhotoService();
        return new FaultReportsController(faultReportService, profileService, collectorProfileService, waterMeterService, photoService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, string? role, IEnumerable<string> permissions)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        if (role is not null)
        {
            claims.Add(new Claim(ClaimNames.UserRole, role));
        }

        foreach (var permission in permissions)
        {
            claims.Add(new Claim(ClaimNames.Permission, permission));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }

    private static IFormFile CreateFormFile(byte[] content, string contentType, string fileName, long? declaredLength = null)
    {
        var stream = new MemoryStream(content);
        return new FormFile(stream, 0, declaredLength ?? content.LongLength, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };
    }
}
