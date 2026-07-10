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
    private const string AdminRole = "Admin";

    [Fact]
    public async Task UploadPhoto_OwnReport_ReturnsCreatedWithMetadataOnly()
    {
        var controller = CreateController(
            BuildUser(userId: 1, role: CustomerRole, permissions: []),
            profiles: [new CustomerProfileResponse { Id = 10, UserId = 1 }],
            reports: [new FaultReportResponse { Id = 1, CustomerId = 10, Title = "Leak", Status = "New" }],
            out _);

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/jpeg", "leak.jpg");

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

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/png", "leak.png");

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

    private static FaultReportsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<CustomerProfileResponse> profiles,
        IEnumerable<FaultReportResponse> reports,
        out FakeFaultReportPhotoService photoService)
    {
        var faultReportService = new FakeFaultReportCrudService(reports);
        var profileService = new FakeCustomerProfileCrudService(profiles);
        photoService = new FakeFaultReportPhotoService();
        return new FaultReportsController(faultReportService, profileService, photoService)
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
