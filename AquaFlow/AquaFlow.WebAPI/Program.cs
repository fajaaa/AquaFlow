using System.Text;
using System.Threading.RateLimiting;
using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using AquaFlow.Services.Validators;
using AquaFlow.Services.WaterMeterRequestStateMachine;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.RateLimiting;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options => options.Filters.Add<ExceptionFilter>());
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, context, cancellationToken) =>
    {
        const string securitySchemeName = JwtBearerDefaults.AuthenticationScheme;

        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes[securitySchemeName] = new OpenApiSecurityScheme
        {
            BearerFormat = "JWT",
            Description = "JWT Authorization header using the Bearer scheme.",
            In = ParameterLocation.Header,
            Name = "Authorization",
            Scheme = JwtBearerDefaults.AuthenticationScheme,
            Type = SecuritySchemeType.Http
        };

        document.SecurityRequirements.Add(new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Id = securitySchemeName,
                        Type = ReferenceType.SecurityScheme
                    }
                },
                Array.Empty<string>()
            }
        });

        return Task.CompletedTask;
    });
});
builder.Services.AddEndpointsApiExplorer();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Connection string 'DefaultConnection' is required because AquaFlow uses SQL Server persistence. " +
        "Set it with the ConnectionStrings__DefaultConnection environment variable or user secrets.");
}

var jwtIssuer = builder.Configuration["JwtToken:Issuer"];
var jwtAudience = builder.Configuration["JwtToken:Audience"];
var jwtSecretKey = builder.Configuration["JwtToken:SecretKey"];
if (string.IsNullOrWhiteSpace(jwtIssuer) ||
    string.IsNullOrWhiteSpace(jwtAudience) ||
    string.IsNullOrWhiteSpace(jwtSecretKey))
{
    throw new InvalidOperationException(
        "JWT configuration is required because authentication is enabled. " +
        "Set JwtToken__Issuer, JwtToken__Audience, and JwtToken__SecretKey with environment variables or user secrets.");
}

builder.Services.AddDbContext<AquaFlowDbContext>(options => options.UseSqlServer(connectionString));

builder.Services.AddCors(options =>
{
    options.AddPolicy("LocalDevelopment", policy =>
    {
        policy
            .SetIsOriginAllowed(IsLocalDevelopmentOrigin)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var mapperConfig = TypeAdapterConfig.GlobalSettings;
mapperConfig.NewConfig<User, UserResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name)
    .Map(destination => destination.FirstName, source => source.CustomerProfile == null ? string.Empty : source.CustomerProfile.FirstName)
    .Map(destination => destination.LastName, source => source.CustomerProfile == null ? string.Empty : source.CustomerProfile.LastName);
mapperConfig.NewConfig<User, UserSensitiveResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name);
mapperConfig.NewConfig<UserRolePermission, UserRolePermissionResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name)
    .Map(destination => destination.PermissionCode, source => source.Permission == null ? string.Empty : source.Permission.Code)
    .Map(destination => destination.PermissionName, source => source.Permission == null ? string.Empty : source.Permission.Name);
mapperConfig.NewConfig<CollectorProfile, CollectorProfileResponse>()
    .Map(destination => destination.AssignedAreaName, source => source.AssignedArea == null ? string.Empty : source.AssignedArea.Name)
    .Map(destination => destination.IsActive, source => source.User != null && source.User.IsActive)
    .Map(destination => destination.FirstName, source => source.User == null || source.User.CustomerProfile == null ? string.Empty : source.User.CustomerProfile.FirstName)
    .Map(destination => destination.LastName, source => source.User == null || source.User.CustomerProfile == null ? string.Empty : source.User.CustomerProfile.LastName)
    .Map(destination => destination.Email, source => source.User == null ? string.Empty : source.User.Email)
    .Map(destination => destination.Phone, source => source.User == null ? string.Empty : source.User.Phone);
mapperConfig.NewConfig<UserNotification, UserNotificationResponse>()
    .Map(destination => destination.Notification, source => source.Notification);
mapperConfig.NewConfig<Municipality, MunicipalityResponse>()
    .Map(destination => destination.CityName, source => source.City == null ? string.Empty : source.City.Name);
mapperConfig.NewConfig<Settlement, SettlementResponse>()
    .Map(destination => destination.MunicipalityName, source => source.Municipality == null ? string.Empty : source.Municipality.Name);
mapperConfig.NewConfig<CustomerProfile, CustomerProfileResponse>()
    .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name);
mapperConfig.NewConfig<WaterMeter, WaterMeterResponse>()
    .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
    .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
    .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName);
mapperConfig.NewConfig<WaterMeterRequest, WaterMeterRequestResponse>()
    .Map(destination => destination.SettlementName, source => source.Settlement == null ? string.Empty : source.Settlement.Name)
    .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
    .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
    .Map(destination => destination.CustomerPhone, source => source.Customer == null || source.Customer.User == null ? null : source.Customer.User.Phone);
mapperConfig.NewConfig<Invoice, InvoiceResponse>()
    .Map(destination => destination.CustomerFirstName, source => source.Customer == null ? string.Empty : source.Customer.FirstName)
    .Map(destination => destination.CustomerLastName, source => source.Customer == null ? string.Empty : source.Customer.LastName)
    .Map(destination => destination.WaterMeterSerialNumber, source => source.WaterMeter == null ? string.Empty : source.WaterMeter.SerialNumber);
builder.Services.AddSingleton(mapperConfig);
builder.Services.AddScoped<IMapper, ServiceMapper>();

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IDeviceTokenService, DeviceTokenService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<IPermissionLookupService, PermissionLookupService>();
builder.Services.AddScoped<NotificationRecipientService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
AddPatchMapping<UserPatchRequest, User>();
builder.Services.AddScoped<IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>>(
    serviceProvider => serviceProvider.GetRequiredService<IUserService>());
AddCrud<UserRole, UserRoleResponse, UserRoleSearchObject, UserRoleInsertRequest, UserRoleUpdateRequest, UserRolePatchRequest>();
AddPatchMapping<PermissionPatchRequest, Permission>();
builder.Services.AddScoped<IBaseCRUDService<PermissionResponse, PermissionSearchObject, PermissionInsertRequest, PermissionUpdateRequest, PermissionPatchRequest>, PermissionService>();
AddPatchMapping<UserRolePermissionPatchRequest, UserRolePermission>();
builder.Services.AddScoped<IBaseCRUDService<UserRolePermissionResponse, UserRolePermissionSearchObject, UserRolePermissionInsertRequest, UserRolePermissionUpdateRequest, UserRolePermissionPatchRequest>, UserRolePermissionService>();
AddPatchMapping<CustomerProfilePatchRequest, CustomerProfile>();
builder.Services.AddScoped<IBaseCRUDService<CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest, CustomerProfilePatchRequest>, CustomerProfileService>();
AddPatchMapping<CollectorProfilePatchRequest, CollectorProfile>();
builder.Services.AddScoped<IBaseCRUDService<CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest, CollectorProfilePatchRequest>, CollectorProfileService>();
// The administrative lookup (City -> Municipality -> Settlement) is registered by hand:
// each service adds case-insensitive uniqueness checks, parent-FK existence checks, and a
// delete guard naming what still references the row; the generic IBaseCRUDService<...>
// alias still resolves to the same service instance.
AddPatchMapping<CityPatchRequest, City>();
builder.Services.AddScoped<IBaseCRUDService<CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityPatchRequest>, CityService>();
AddPatchMapping<MunicipalityPatchRequest, Municipality>();
builder.Services.AddScoped<IBaseCRUDService<MunicipalityResponse, MunicipalitySearchObject, MunicipalityInsertRequest, MunicipalityUpdateRequest, MunicipalityPatchRequest>, MunicipalityService>();
AddPatchMapping<SettlementPatchRequest, Settlement>();
builder.Services.AddScoped<IBaseCRUDService<SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest, SettlementPatchRequest>, SettlementService>();
AddPatchMapping<WaterMeterPatchRequest, WaterMeter>();
builder.Services.AddScoped<IBaseCRUDService<WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>, WaterMeterService>();
// MeterReading is registered by hand (not AddCrud<>) because the collector data-entry flow
// (CreateForCollectorAsync) needs billing-cycle resolution/validation and WaterMeter.LastReading
// updates beyond the generic EfCrudService; the generic IBaseCRUDService alias still resolves to
// the same MeterReadingService instance, same pattern as WaterMeterRequest/Invoice below.
AddPatchMapping<MeterReadingPatchRequest, MeterReading>();
builder.Services.AddScoped<IMeterReadingService, MeterReadingService>();
builder.Services.AddScoped<IBaseCRUDService<MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingPatchRequest>>(
    serviceProvider => serviceProvider.GetRequiredService<IMeterReadingService>());
AddPatchMapping<TariffPatchRequest, Tariff>();
builder.Services.AddScoped<IBaseCRUDService<TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest, TariffPatchRequest>, TariffService>();
AddPatchMapping<BillingCyclePatchRequest, BillingCycle>();
builder.Services.AddScoped<IBillingCycleService, BillingCycleService>();
// Invoice uses the state machine (InvoiceService) instead of the generic CRUD service, so register
// it by hand: the patch mapping, IInvoiceService, and the generic IBaseCRUDService alias resolving
// to the same InvoiceService. Each invoice state is a keyed scoped BaseInvoiceState (status string as
// key); IInvoiceStateResolver resolves the state for a status through those keyed registrations.
AddPatchMapping<InvoicePatchRequest, Invoice>();
builder.Services.AddScoped<IInvoiceService, InvoiceService>();
builder.Services.AddScoped<IBaseCRUDService<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>>(
    serviceProvider => serviceProvider.GetRequiredService<IInvoiceService>());
builder.Services.AddKeyedScoped<BaseInvoiceState, DraftInvoiceState>(InvoiceStatus.Draft);
builder.Services.AddKeyedScoped<BaseInvoiceState, IssuedInvoiceState>(InvoiceStatus.Issued);
builder.Services.AddKeyedScoped<BaseInvoiceState, PartiallyPaidInvoiceState>(InvoiceStatus.PartiallyPaid);
builder.Services.AddKeyedScoped<BaseInvoiceState, OverdueInvoiceState>(InvoiceStatus.Overdue);
builder.Services.AddKeyedScoped<BaseInvoiceState, PaidInvoiceState>(InvoiceStatus.Paid);
builder.Services.AddKeyedScoped<BaseInvoiceState, CancelledInvoiceState>(InvoiceStatus.Cancelled);
builder.Services.AddScoped<IInvoiceStateResolver, InvoiceStateResolver>();
// WaterMeterRequest mirrors the Invoice registration above: the state machine service is
// registered by hand, the generic IBaseCRUDService alias resolves to the same instance, and each
// request state is a keyed scoped BaseWaterMeterRequestState (status string as key) that
// IWaterMeterRequestStateResolver resolves through.
AddPatchMapping<WaterMeterRequestPatchRequest, WaterMeterRequest>();
builder.Services.AddScoped<IWaterMeterRequestService, WaterMeterRequestService>();
builder.Services.AddScoped<IBaseCRUDService<WaterMeterRequestResponse, WaterMeterRequestSearchObject, WaterMeterRequestInsertRequest, WaterMeterRequestUpdateRequest, WaterMeterRequestPatchRequest>>(
    serviceProvider => serviceProvider.GetRequiredService<IWaterMeterRequestService>());
builder.Services.AddKeyedScoped<BaseWaterMeterRequestState, PendingWaterMeterRequestState>(WaterMeterRequestStatus.Pending);
builder.Services.AddKeyedScoped<BaseWaterMeterRequestState, AssignedWaterMeterRequestState>(WaterMeterRequestStatus.Assigned);
builder.Services.AddKeyedScoped<BaseWaterMeterRequestState, RegisteredWaterMeterRequestState>(WaterMeterRequestStatus.Registered);
builder.Services.AddKeyedScoped<BaseWaterMeterRequestState, RejectedWaterMeterRequestState>(WaterMeterRequestStatus.Rejected);
builder.Services.AddKeyedScoped<BaseWaterMeterRequestState, CancelledWaterMeterRequestState>(WaterMeterRequestStatus.Cancelled);
builder.Services.AddScoped<IWaterMeterRequestStateResolver, WaterMeterRequestStateResolver>();
AddCrud<InvoiceItem, InvoiceItemResponse, InvoiceItemSearchObject, InvoiceItemInsertRequest, InvoiceItemUpdateRequest, InvoiceItemPatchRequest>();
AddCrud<Payment, PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest>();
AddCrud<FaultReport, FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>();
AddPatchMapping<NotificationPatchRequest, Notification>();
builder.Services.AddScoped<IBaseCRUDService<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest>, NotificationService>();
AddPatchMapping<UserNotificationPatchRequest, UserNotification>();
builder.Services.AddScoped<IBaseCRUDService<UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest>, UserNotificationService>();
AddCrud<CompanySettings, CompanySettingsResponse, CompanySettingsSearchObject, CompanySettingsInsertRequest, CompanySettingsUpdateRequest, CompanySettingsPatchRequest>();
AddCrud<PaymentSettings, PaymentSettingsResponse, PaymentSettingsSearchObject, PaymentSettingsInsertRequest, PaymentSettingsUpdateRequest, PaymentSettingsPatchRequest>();

builder.Services.AddScoped<IValidator<UserRegisterRequest>, UserRegisterValidator>();
builder.Services.AddScoped<IValidator<AccountUpdateRequest>, AccountUpdateValidator>();
builder.Services.AddScoped<IValidator<AccountChangePasswordRequest>, AccountChangePasswordValidator>();
builder.Services.AddScoped<IValidator<DeviceTokenRegisterRequest>, DeviceTokenRegisterValidator>();
builder.Services.AddScoped<IValidator<DeviceTokenUnregisterRequest>, DeviceTokenUnregisterValidator>();
builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<UserPatchRequest>, UserPatchValidator>();
builder.Services.AddScoped<IValidator<UserRoleInsertRequest>, UserRoleInsertValidator>();
builder.Services.AddScoped<IValidator<UserRoleUpdateRequest>, UserRoleUpdateValidator>();
builder.Services.AddScoped<IValidator<UserRolePatchRequest>, UserRolePatchValidator>();
builder.Services.AddScoped<IValidator<PermissionInsertRequest>, PermissionInsertValidator>();
builder.Services.AddScoped<IValidator<PermissionUpdateRequest>, PermissionUpdateValidator>();
builder.Services.AddScoped<IValidator<PermissionPatchRequest>, PermissionPatchValidator>();
builder.Services.AddScoped<IValidator<UserRolePermissionInsertRequest>, UserRolePermissionInsertValidator>();
builder.Services.AddScoped<IValidator<UserRolePermissionUpdateRequest>, UserRolePermissionUpdateValidator>();
builder.Services.AddScoped<IValidator<UserRolePermissionPatchRequest>, UserRolePermissionPatchValidator>();
builder.Services.AddScoped<IValidator<CustomerProfileInsertRequest>, CustomerProfileInsertValidator>();
builder.Services.AddScoped<IValidator<CustomerProfileUpdateRequest>, CustomerProfileUpdateValidator>();
builder.Services.AddScoped<IValidator<CustomerProfilePatchRequest>, CustomerProfilePatchValidator>();
builder.Services.AddScoped<IValidator<CollectorProfileInsertRequest>, CollectorProfileInsertValidator>();
builder.Services.AddScoped<IValidator<CollectorProfileUpdateRequest>, CollectorProfileUpdateValidator>();
builder.Services.AddScoped<IValidator<CollectorProfilePatchRequest>, CollectorProfilePatchValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<CityPatchRequest>, CityPatchValidator>();
builder.Services.AddScoped<IValidator<MunicipalityInsertRequest>, MunicipalityInsertValidator>();
builder.Services.AddScoped<IValidator<MunicipalityUpdateRequest>, MunicipalityUpdateValidator>();
builder.Services.AddScoped<IValidator<MunicipalityPatchRequest>, MunicipalityPatchValidator>();
builder.Services.AddScoped<IValidator<SettlementInsertRequest>, SettlementInsertValidator>();
builder.Services.AddScoped<IValidator<SettlementUpdateRequest>, SettlementUpdateValidator>();
builder.Services.AddScoped<IValidator<SettlementPatchRequest>, SettlementPatchValidator>();
builder.Services.AddScoped<IValidator<WaterMeterInsertRequest>, WaterMeterInsertValidator>();
builder.Services.AddScoped<IValidator<WaterMeterUpdateRequest>, WaterMeterUpdateValidator>();
builder.Services.AddScoped<IValidator<WaterMeterPatchRequest>, WaterMeterPatchValidator>();
builder.Services.AddScoped<IValidator<WaterMeterRequestInsertRequest>, WaterMeterRequestInsertValidator>();
builder.Services.AddScoped<IValidator<WaterMeterRequestUpdateRequest>, WaterMeterRequestUpdateValidator>();
builder.Services.AddScoped<IValidator<WaterMeterRequestPatchRequest>, WaterMeterRequestPatchValidator>();
builder.Services.AddScoped<IValidator<MeterReadingInsertRequest>, MeterReadingInsertValidator>();
builder.Services.AddScoped<IValidator<MeterReadingUpdateRequest>, MeterReadingUpdateValidator>();
builder.Services.AddScoped<IValidator<MeterReadingPatchRequest>, MeterReadingPatchValidator>();
builder.Services.AddScoped<IValidator<MeterReadingCollectorEntryRequest>, MeterReadingCollectorEntryValidator>();
builder.Services.AddScoped<IValidator<TariffInsertRequest>, TariffInsertValidator>();
builder.Services.AddScoped<IValidator<TariffUpdateRequest>, TariffUpdateValidator>();
builder.Services.AddScoped<IValidator<TariffPatchRequest>, TariffPatchValidator>();
builder.Services.AddScoped<IValidator<BillingCycleInsertRequest>, BillingCycleInsertValidator>();
builder.Services.AddScoped<IValidator<BillingCycleUpdateRequest>, BillingCycleUpdateValidator>();
builder.Services.AddScoped<IValidator<BillingCyclePatchRequest>, BillingCyclePatchValidator>();
builder.Services.AddScoped<IValidator<InvoiceInsertRequest>, InvoiceInsertValidator>();
builder.Services.AddScoped<IValidator<InvoiceUpdateRequest>, InvoiceUpdateValidator>();
builder.Services.AddScoped<IValidator<InvoicePatchRequest>, InvoicePatchValidator>();
builder.Services.AddScoped<IValidator<InvoiceItemInsertRequest>, InvoiceItemInsertValidator>();
builder.Services.AddScoped<IValidator<InvoiceItemUpdateRequest>, InvoiceItemUpdateValidator>();
builder.Services.AddScoped<IValidator<InvoiceItemPatchRequest>, InvoiceItemPatchValidator>();
builder.Services.AddScoped<IValidator<PaymentInsertRequest>, PaymentInsertValidator>();
builder.Services.AddScoped<IValidator<PaymentUpdateRequest>, PaymentUpdateValidator>();
builder.Services.AddScoped<IValidator<PaymentPatchRequest>, PaymentPatchValidator>();
builder.Services.AddScoped<IValidator<FaultReportInsertRequest>, FaultReportInsertValidator>();
builder.Services.AddScoped<IValidator<FaultReportUpdateRequest>, FaultReportUpdateValidator>();
builder.Services.AddScoped<IValidator<FaultReportPatchRequest>, FaultReportPatchValidator>();
builder.Services.AddScoped<IValidator<NotificationInsertRequest>, NotificationInsertValidator>();
builder.Services.AddScoped<IValidator<NotificationUpdateRequest>, NotificationUpdateValidator>();
builder.Services.AddScoped<IValidator<NotificationPatchRequest>, NotificationPatchValidator>();
builder.Services.AddScoped<IValidator<UserNotificationInsertRequest>, UserNotificationInsertValidator>();
builder.Services.AddScoped<IValidator<UserNotificationUpdateRequest>, UserNotificationUpdateValidator>();
builder.Services.AddScoped<IValidator<UserNotificationPatchRequest>, UserNotificationPatchValidator>();
builder.Services.AddScoped<IValidator<CompanySettingsInsertRequest>, CompanySettingsInsertValidator>();
builder.Services.AddScoped<IValidator<CompanySettingsUpdateRequest>, CompanySettingsUpdateValidator>();
builder.Services.AddScoped<IValidator<CompanySettingsPatchRequest>, CompanySettingsPatchValidator>();
builder.Services.AddScoped<IValidator<PaymentSettingsInsertRequest>, PaymentSettingsInsertValidator>();
builder.Services.AddScoped<IValidator<PaymentSettingsUpdateRequest>, PaymentSettingsUpdateValidator>();
builder.Services.AddScoped<IValidator<PaymentSettingsPatchRequest>, PaymentSettingsPatchValidator>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
});
builder.Services.AddAuthorization();

// Throttle the credential endpoints so /Access/login (and /refresh) cannot be brute-forced.
// Partitioned per client IP: 5 attempts per minute, further requests get 429.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy(RateLimitingPolicies.Authentication, httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1)
            }));

    // Applied to every request regardless of controller/action ([RateLimitingPolicies.Standard]).
    // A global limiter always stacks with any endpoint-specific policy (e.g. the stricter
    // Authentication policy on /Access/login still applies on top of this), so this closes the
    // gap for every other endpoint - including read endpoints like /UserNotifications/{id} -
    // without weakening the login throttle. Partitioned per authenticated user where possible
    // (falls back to client IP for anonymous calls) so one user hammering the API can't exhaust
    // another user's quota. The limit is generous enough that normal UI usage never hits it, but
    // low enough that scripted ID enumeration (e.g. GET /UserNotifications/1, /2, /3...) is
    // throttled and shows up as a burst of 429s.
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var userId = httpContext.User.FindFirst(ClaimNames.Id)?.Value;
        var partitionKey = !string.IsNullOrEmpty(userId)
            ? $"user:{userId}"
            : $"ip:{httpContext.Connection.RemoteIpAddress}";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey,
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1)
            });
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
    app.MapGet("/", () => Results.Redirect("/scalar/v1"));
}

app.UseHttpsRedirection();

if (app.Environment.IsDevelopment())
{
    app.UseCors("LocalDevelopment");
}

app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

app.MapControllers();

app.Run();

void AddCrud<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>()
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    AddPatchMapping<TPatchRequest, TEntity>();

    builder.Services.AddScoped<IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>>(serviceProvider =>
        ActivatorUtilities.CreateInstance<EfCrudService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>>(serviceProvider));
}

void AddPatchMapping<TPatchRequest, TEntity>()
    where TEntity : EntityBase
{
    mapperConfig.NewConfig<TPatchRequest, TEntity>()
        .IgnoreNullValues(true);
}

static bool IsLocalDevelopmentOrigin(string origin)
{
    if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
    {
        return false;
    }

    if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
    {
        return false;
    }

    return uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase) ||
        uri.Host.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase) ||
        uri.Host.StartsWith("192.168.", StringComparison.OrdinalIgnoreCase);
}
