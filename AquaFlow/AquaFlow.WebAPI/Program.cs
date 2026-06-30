using System.Text;
using AquaFlow.Common.Services.CryptoService;
using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using AquaFlow.WebAPI.Filters;
using AquaFlow.WebAPI.Services.AccessManager;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
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

var mapperConfig = TypeAdapterConfig.GlobalSettings;
mapperConfig.NewConfig<User, UserResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name);
mapperConfig.NewConfig<User, UserSensitiveResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name);
mapperConfig.NewConfig<UserRolePermission, UserRolePermissionResponse>()
    .Map(destination => destination.UserRole, source => source.UserRole == null ? string.Empty : source.UserRole.Name)
    .Map(destination => destination.PermissionCode, source => source.Permission == null ? string.Empty : source.Permission.Code)
    .Map(destination => destination.PermissionName, source => source.Permission == null ? string.Empty : source.Permission.Name);
builder.Services.AddSingleton(mapperConfig);
builder.Services.AddScoped<IMapper, ServiceMapper>();

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
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
AddCrud<Settlement, SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest, SettlementPatchRequest>();
AddCrud<ServiceLocation, ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest, ServiceLocationPatchRequest>();
AddCrud<WaterMeter, WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest, WaterMeterPatchRequest>();
AddCrud<MeterReading, MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest, MeterReadingPatchRequest>();
AddCrud<Tariff, TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest, TariffPatchRequest>();
AddCrud<Invoice, InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>();
AddCrud<InvoiceItem, InvoiceItemResponse, InvoiceItemSearchObject, InvoiceItemInsertRequest, InvoiceItemUpdateRequest, InvoiceItemPatchRequest>();
AddCrud<Payment, PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentPatchRequest>();
AddCrud<FaultReport, FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>();
AddCrud<Notification, NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationPatchRequest>();
AddCrud<UserNotification, UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest, UserNotificationPatchRequest>();
AddCrud<CompanySettings, CompanySettingsResponse, CompanySettingsSearchObject, CompanySettingsInsertRequest, CompanySettingsUpdateRequest, CompanySettingsPatchRequest>();
AddCrud<PaymentSettings, PaymentSettingsResponse, PaymentSettingsSearchObject, PaymentSettingsInsertRequest, PaymentSettingsUpdateRequest, PaymentSettingsPatchRequest>();

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
builder.Services.AddScoped<IValidator<SettlementInsertRequest>, SettlementInsertValidator>();
builder.Services.AddScoped<IValidator<SettlementUpdateRequest>, SettlementUpdateValidator>();
builder.Services.AddScoped<IValidator<SettlementPatchRequest>, SettlementPatchValidator>();
builder.Services.AddScoped<IValidator<ServiceLocationInsertRequest>, ServiceLocationInsertValidator>();
builder.Services.AddScoped<IValidator<ServiceLocationUpdateRequest>, ServiceLocationUpdateValidator>();
builder.Services.AddScoped<IValidator<ServiceLocationPatchRequest>, ServiceLocationPatchValidator>();
builder.Services.AddScoped<IValidator<WaterMeterInsertRequest>, WaterMeterInsertValidator>();
builder.Services.AddScoped<IValidator<WaterMeterUpdateRequest>, WaterMeterUpdateValidator>();
builder.Services.AddScoped<IValidator<WaterMeterPatchRequest>, WaterMeterPatchValidator>();
builder.Services.AddScoped<IValidator<MeterReadingInsertRequest>, MeterReadingInsertValidator>();
builder.Services.AddScoped<IValidator<MeterReadingUpdateRequest>, MeterReadingUpdateValidator>();
builder.Services.AddScoped<IValidator<MeterReadingPatchRequest>, MeterReadingPatchValidator>();
builder.Services.AddScoped<IValidator<TariffInsertRequest>, TariffInsertValidator>();
builder.Services.AddScoped<IValidator<TariffUpdateRequest>, TariffUpdateValidator>();
builder.Services.AddScoped<IValidator<TariffPatchRequest>, TariffPatchValidator>();
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

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
    app.MapGet("/", () => Results.Redirect("/scalar/v1"));
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

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
