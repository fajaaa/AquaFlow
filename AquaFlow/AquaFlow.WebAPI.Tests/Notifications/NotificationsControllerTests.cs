using System.Security.Claims;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using AquaFlow.WebAPI.Tests.UserNotifications;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Notifications;

public class NotificationsControllerTests
{
    private const string ManagePermission = "Notifications.Manage";

    // CreatedById must come from the caller's JWT, never from the request body -
    // otherwise any Notifications.Manage holder could name a different user as the
    // author of a notification they themselves created.
    [Fact]
    public async Task Create_ClientSuppliedCreatedById_IsReplacedWithCallersJwtId()
    {
        var controller = CreateController(BuildUser(userId: 42));

        var request = new NotificationInsertRequest
        {
            Title = "Test",
            Body = "Body",
            Type = "Info",
            Audience = "All",
            CreatedById = 999 // attempt to impersonate another user as the author
        };

        var result = await controller.Create(request);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(created.Value);
        Assert.Equal(42, response.CreatedById);
    }

    // Editing a notification must not let the caller reassign its authorship: the
    // original CreatedById is preserved regardless of what the request supplies.
    [Fact]
    public async Task Update_ClientSuppliedCreatedById_IsIgnoredAndOriginalIsKept()
    {
        var controller = CreateController(
            BuildUser(userId: 42),
            new NotificationResponse { Id = 1, Title = "A", Audience = "All", CreatedById = 7 });

        var request = new NotificationUpdateRequest
        {
            Title = "A - edited",
            Body = "Body",
            Type = "Info",
            Audience = "All",
            CreatedById = 999 // attempt to reassign authorship
        };

        var result = await controller.Update(1, request);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(7, response.CreatedById);
    }

    [Fact]
    public async Task Patch_ClientSuppliedCreatedById_IsIgnoredAndOriginalIsKept()
    {
        var controller = CreateController(
            BuildUser(userId: 42),
            new NotificationResponse { Id = 1, Title = "A", Audience = "All", CreatedById = 7 });

        var request = new NotificationPatchRequest { CreatedById = 999 };

        var result = await controller.Patch(1, request);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(7, response.CreatedById);
    }

    [Fact]
    public async Task GetAll_ReturnsAllRows()
    {
        var controller = CreateController(
            new NotificationResponse { Id = 1, Title = "A", Audience = "All" },
            new NotificationResponse { Id = 2, Title = "B", Audience = "Customers" });

        var result = await controller.GetAll(null);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var page = Assert.IsType<PageResult<NotificationResponse>>(ok.Value);
        Assert.Equal(2, page.Items.Count);
    }

    [Fact]
    public async Task GetById_ExistingId_ReturnsOk()
    {
        var controller = CreateController(new NotificationResponse { Id = 1, Title = "A", Audience = "All" });

        var result = await controller.GetById(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<NotificationResponse>(ok.Value);
        Assert.Equal(1, response.Id);
    }

    [Fact]
    public async Task GetById_MissingId_ReturnsNotFound()
    {
        var controller = CreateController();

        var result = await controller.GetById(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    // /Notifications is the raw admin table (unfiltered by Audience/SettlementId), so every
    // action - including reads - must require Notifications.Manage. The self-service path
    // for an ordinary user is GET /UserNotifications/mine instead. Enforcement runs in the
    // MVC authorization filter pipeline, which a direct method call in these tests bypasses
    // (see AquaFlow.WebAPI.Tests remarks in AGENTS.md), so this pins the declarative gate
    // itself: if [RequirePermission] is ever dropped from one of these actions, this test
    // fails instead of silently reopening the information disclosure.
    [Theory]
    [InlineData(nameof(NotificationsController.GetAll))]
    [InlineData(nameof(NotificationsController.GetById))]
    [InlineData(nameof(NotificationsController.Create))]
    [InlineData(nameof(NotificationsController.Update))]
    [InlineData(nameof(NotificationsController.Patch))]
    [InlineData(nameof(NotificationsController.Delete))]
    [InlineData(nameof(NotificationsController.CreateWithImages))]
    [InlineData(nameof(NotificationsController.UploadImage))]
    [InlineData(nameof(NotificationsController.DeleteImage))]
    public void Action_RequiresNotificationsManagePermission(string methodName)
    {
        var method = typeof(NotificationsController)
            .GetMethods()
            .Single(m => m.Name == methodName && m.DeclaringType == typeof(NotificationsController));

        var attribute = method
            .GetCustomAttributes(typeof(RequirePermissionAttribute), inherit: false)
            .Cast<RequirePermissionAttribute>()
            .SingleOrDefault();

        Assert.NotNull(attribute);
        var codes = Assert.IsType<string[]>(attribute!.Arguments![0]);
        Assert.Contains(ManagePermission, codes);
    }

    [Fact]
    public async Task UploadImage_ManageHolder_ReturnsCreatedWithMetadataOnly()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out _);

        var file = CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF }, "image/jpeg", "works.jpg");

        var result = await controller.UploadImage(1, file);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var response = Assert.IsType<NotificationImageResponse>(created.Value);
        Assert.Equal("works.jpg", response.FileName);
        Assert.Equal("image/jpeg", response.ContentType);
    }

    [Fact]
    public async Task UploadImage_UnknownNotificationId_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 99, ManagePermission), [], [], out _);

        var file = CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF }, "image/jpeg", "works.jpg");

        var result = await controller.UploadImage(999, file);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task UploadImage_SixthImage_ThrowsClientException()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out var imageService);
        for (var i = 0; i < 5; i++)
        {
            await imageService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", $"{i}.jpg");
        }

        var file = CreateFormFile(new byte[] { 1, 2, 3 }, "image/jpeg", "sixth.jpg");

        await Assert.ThrowsAsync<ClientException>(() => controller.UploadImage(1, file));
    }

    [Fact]
    public async Task CreateWithImages_ValidImages_CreatesWithCallersJwtIdAndSniffedContentType()
    {
        var service = new FakeNotificationCrudService([]);
        var controller = CreateWithImagesController(service, userId: 42);
        var images = new FormFileCollection
        {
            // Declared as PNG but the bytes are JPEG: the stored type must come from the signature.
            CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF, 1 }, "image/png", "a.png"),
            CreateFormFile(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, "image/png", "b.png")
        };

        var result = await controller.CreateWithImages(
            new NotificationWithImagesRequest { Title = "T", Body = "B", Type = "Info", Audience = "All" },
            images);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(42, Assert.IsType<NotificationResponse>(created.Value).CreatedById);
        Assert.NotNull(service.LastImages);
        Assert.Equal(2, service.LastImages!.Count);
        Assert.Equal("image/jpeg", service.LastImages[0].ContentType);
    }

    [Fact]
    public async Task CreateWithImages_InvalidImage_ThrowsClientExceptionAndServiceIsNeverCalled()
    {
        var service = new FakeNotificationCrudService([]);
        var controller = CreateWithImagesController(service, userId: 42);
        var images = new FormFileCollection
        {
            CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF, 1 }, "image/jpeg", "ok.jpg"),
            // Right declared type, but the bytes are not an image.
            CreateFormFile(new byte[] { 1, 2, 3, 4 }, "image/jpeg", "fake.jpg")
        };

        await Assert.ThrowsAsync<ClientException>(() => controller.CreateWithImages(
            new NotificationWithImagesRequest { Title = "T", Body = "B" },
            images));

        Assert.Null(service.LastImages);
        Assert.Empty((await service.GetAllAsync()).Items);
    }

    [Fact]
    public async Task CreateWithImages_SixImages_ThrowsClientException()
    {
        var service = new FakeNotificationCrudService([]);
        var controller = CreateWithImagesController(service, userId: 42);
        var images = new FormFileCollection();
        for (var i = 0; i < 6; i++)
        {
            images.Add(CreateFormFile(new byte[] { 0xFF, 0xD8, 0xFF, 1 }, "image/jpeg", $"{i}.jpg"));
        }

        await Assert.ThrowsAsync<ClientException>(() => controller.CreateWithImages(
            new NotificationWithImagesRequest { Title = "T", Body = "B" },
            images));

        Assert.Null(service.LastImages);
    }

    private static NotificationsController CreateWithImagesController(FakeNotificationCrudService service, int userId)
    {
        return new NotificationsController(service, new FakeNotificationImageService(), new FakeUserNotificationCrudService([]))
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = BuildUser(userId, ManagePermission) }
            }
        };
    }

    [Fact]
    public async Task DeleteImage_ManageHolder_ReturnsNoContent()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out var imageService);
        var uploaded = await imageService.UploadAsync(1, new byte[] { 1 }, "image/jpeg", "a.jpg");

        var result = await controller.DeleteImage(1, uploaded.Id);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteImage_UnknownImage_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 99, ManagePermission), [], [], out _);

        var result = await controller.DeleteImage(1, 999);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetImages_ManageHolder_ReturnsMetadata()
    {
        var controller = CreateController(
            BuildUser(userId: 99, ManagePermission),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out var imageService);
        await imageService.UploadAsync(1, new byte[] { 1, 2, 3 }, "image/jpeg", "a.jpg");

        var result = await controller.GetImages(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var items = Assert.IsAssignableFrom<List<NotificationImageResponse>>(ok.Value);
        Assert.Single(items);
    }

    // A Manage holder skips the recipient-row lookup entirely, so without this check a
    // nonexistent notification id would silently return an empty image list instead of 404.
    [Fact]
    public async Task GetImages_ManageHolder_UnknownNotificationId_ReturnsNotFound()
    {
        var controller = CreateController(BuildUser(userId: 99, ManagePermission), [], [], out _);

        var result = await controller.GetImages(999);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetImages_RecipientWithUserNotificationRow_ReturnsMetadata()
    {
        var controller = CreateController(
            BuildUser(userId: 5),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [new UserNotificationResponse { Id = 1, UserId = 5, NotificationId = 1 }],
            out var imageService);
        await imageService.UploadAsync(1, new byte[] { 1, 2, 3 }, "image/jpeg", "a.jpg");

        var result = await controller.GetImages(1);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var items = Assert.IsAssignableFrom<List<NotificationImageResponse>>(ok.Value);
        Assert.Single(items);
    }

    // A caller with no UserNotification row for this notification - never delivered to them
    // per their audience - gets NotFound, not Forbid, so the response never confirms whether
    // the notification id exists.
    [Fact]
    public async Task GetImages_NonRecipientNonManage_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 5),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [new UserNotificationResponse { Id = 1, UserId = 5, NotificationId = 2 }],
            out _);

        var result = await controller.GetImages(1);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetImage_RecipientWithUserNotificationRow_ReturnsRawBytes()
    {
        var controller = CreateController(
            BuildUser(userId: 5),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [new UserNotificationResponse { Id = 1, UserId = 5, NotificationId = 1 }],
            out var imageService);
        var uploaded = await imageService.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/jpeg", "a.jpg");

        var result = await controller.GetImage(1, uploaded.Id);

        var fileResult = Assert.IsType<FileContentResult>(result);
        Assert.Equal(new byte[] { 9, 8, 7 }, fileResult.FileContents);
        Assert.Equal("image/jpeg", fileResult.ContentType);
    }

    [Fact]
    public async Task GetImage_NonRecipientNonManage_ReturnsNotFound()
    {
        var controller = CreateController(
            BuildUser(userId: 5),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out var imageService);
        var uploaded = await imageService.UploadAsync(1, new byte[] { 9, 8, 7 }, "image/jpeg", "a.jpg");

        var result = await controller.GetImage(1, uploaded.Id);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetImages_Unauthenticated_ReturnsUnauthorized()
    {
        var controller = CreateController(
            BuildUser(userId: null),
            [new NotificationResponse { Id = 1, Title = "Works", Audience = "All" }],
            [],
            out _);

        var result = await controller.GetImages(1);

        Assert.IsType<UnauthorizedResult>(result.Result);
    }

    private static NotificationsController CreateController(params NotificationResponse[] rows)
    {
        var service = new FakeNotificationCrudService(rows);
        return new NotificationsController(service, new FakeNotificationImageService(), new FakeUserNotificationCrudService([]));
    }

    private static NotificationsController CreateController(ClaimsPrincipal user, params NotificationResponse[] rows)
    {
        var service = new FakeNotificationCrudService(rows);
        return new NotificationsController(service, new FakeNotificationImageService(), new FakeUserNotificationCrudService([]))
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static NotificationsController CreateController(
        ClaimsPrincipal user,
        IEnumerable<NotificationResponse> rows,
        IEnumerable<UserNotificationResponse> userNotifications,
        out FakeNotificationImageService imageService)
    {
        var service = new FakeNotificationCrudService(rows);
        imageService = new FakeNotificationImageService();
        var userNotificationService = new FakeUserNotificationCrudService(userNotifications);
        return new NotificationsController(service, imageService, userNotificationService)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            }
        };
    }

    private static IFormFile CreateFormFile(byte[] content, string contentType, string fileName)
    {
        var stream = new MemoryStream(content);
        return new FormFile(stream, 0, content.LongLength, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };
    }

    private static ClaimsPrincipal BuildUser(int? userId, params string[] permissions)
    {
        var claims = new List<Claim>();
        if (userId is not null)
        {
            claims.Add(new Claim(ClaimNames.Id, userId.Value.ToString()));
        }

        claims.AddRange(permissions.Select(permission => new Claim(ClaimNames.Permission, permission)));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        return new ClaimsPrincipal(identity);
    }
}
