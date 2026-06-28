using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.Services.InMemory;
using AquaFlow.Services.Validators;
using AquaFlow.WebAPI.Filters;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options => options.Filters.Add<ExceptionFilter>());
builder.Services.AddOpenApi();

var mapperConfig = TypeAdapterConfig.GlobalSettings;
builder.Services.AddSingleton(mapperConfig);
builder.Services.AddScoped<IMapper, ServiceMapper>();

AddCrud<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>(AquaFlowDataStore.Users);
AddCrud<CustomerProfile, CustomerProfileResponse, CustomerProfileSearchObject, CustomerProfileInsertRequest, CustomerProfileUpdateRequest>(AquaFlowDataStore.CustomerProfiles);
AddCrud<CollectorProfile, CollectorProfileResponse, CollectorProfileSearchObject, CollectorProfileInsertRequest, CollectorProfileUpdateRequest>(AquaFlowDataStore.CollectorProfiles);
AddCrud<Settlement, SettlementResponse, SettlementSearchObject, SettlementInsertRequest, SettlementUpdateRequest>(AquaFlowDataStore.Settlements);
AddCrud<ServiceLocation, ServiceLocationResponse, ServiceLocationSearchObject, ServiceLocationInsertRequest, ServiceLocationUpdateRequest>(AquaFlowDataStore.ServiceLocations);
AddCrud<WaterMeter, WaterMeterResponse, WaterMeterSearchObject, WaterMeterInsertRequest, WaterMeterUpdateRequest>(AquaFlowDataStore.WaterMeters);
AddCrud<MeterReading, MeterReadingResponse, MeterReadingSearchObject, MeterReadingInsertRequest, MeterReadingUpdateRequest>(AquaFlowDataStore.MeterReadings);
AddCrud<Tariff, TariffResponse, TariffSearchObject, TariffInsertRequest, TariffUpdateRequest>(AquaFlowDataStore.Tariffs);
AddCrud<Invoice, InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest>(AquaFlowDataStore.Invoices);
AddCrud<InvoiceItem, InvoiceItemResponse, InvoiceItemSearchObject, InvoiceItemInsertRequest, InvoiceItemUpdateRequest>(AquaFlowDataStore.InvoiceItems);
AddCrud<Payment, PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest>(AquaFlowDataStore.Payments);
AddCrud<FaultReport, FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest>(AquaFlowDataStore.FaultReports);
AddCrud<Notification, NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>(AquaFlowDataStore.Notifications);
AddCrud<UserNotification, UserNotificationResponse, UserNotificationSearchObject, UserNotificationInsertRequest, UserNotificationUpdateRequest>(AquaFlowDataStore.UserNotifications);
AddCrud<CompanySettings, CompanySettingsResponse, CompanySettingsSearchObject, CompanySettingsInsertRequest, CompanySettingsUpdateRequest>(AquaFlowDataStore.CompanySettings);
AddCrud<PaymentSettings, PaymentSettingsResponse, PaymentSettingsSearchObject, PaymentSettingsInsertRequest, PaymentSettingsUpdateRequest>(AquaFlowDataStore.PaymentSettings);

builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<CustomerProfileInsertRequest>, CustomerProfileInsertValidator>();
builder.Services.AddScoped<IValidator<CustomerProfileUpdateRequest>, CustomerProfileUpdateValidator>();
builder.Services.AddScoped<IValidator<CollectorProfileInsertRequest>, CollectorProfileInsertValidator>();
builder.Services.AddScoped<IValidator<CollectorProfileUpdateRequest>, CollectorProfileUpdateValidator>();
builder.Services.AddScoped<IValidator<SettlementInsertRequest>, SettlementInsertValidator>();
builder.Services.AddScoped<IValidator<SettlementUpdateRequest>, SettlementUpdateValidator>();
builder.Services.AddScoped<IValidator<ServiceLocationInsertRequest>, ServiceLocationInsertValidator>();
builder.Services.AddScoped<IValidator<ServiceLocationUpdateRequest>, ServiceLocationUpdateValidator>();
builder.Services.AddScoped<IValidator<WaterMeterInsertRequest>, WaterMeterInsertValidator>();
builder.Services.AddScoped<IValidator<WaterMeterUpdateRequest>, WaterMeterUpdateValidator>();
builder.Services.AddScoped<IValidator<MeterReadingInsertRequest>, MeterReadingInsertValidator>();
builder.Services.AddScoped<IValidator<MeterReadingUpdateRequest>, MeterReadingUpdateValidator>();
builder.Services.AddScoped<IValidator<TariffInsertRequest>, TariffInsertValidator>();
builder.Services.AddScoped<IValidator<TariffUpdateRequest>, TariffUpdateValidator>();
builder.Services.AddScoped<IValidator<InvoiceInsertRequest>, InvoiceInsertValidator>();
builder.Services.AddScoped<IValidator<InvoiceUpdateRequest>, InvoiceUpdateValidator>();
builder.Services.AddScoped<IValidator<InvoiceItemInsertRequest>, InvoiceItemInsertValidator>();
builder.Services.AddScoped<IValidator<InvoiceItemUpdateRequest>, InvoiceItemUpdateValidator>();
builder.Services.AddScoped<IValidator<PaymentInsertRequest>, PaymentInsertValidator>();
builder.Services.AddScoped<IValidator<PaymentUpdateRequest>, PaymentUpdateValidator>();
builder.Services.AddScoped<IValidator<FaultReportInsertRequest>, FaultReportInsertValidator>();
builder.Services.AddScoped<IValidator<FaultReportUpdateRequest>, FaultReportUpdateValidator>();
builder.Services.AddScoped<IValidator<NotificationInsertRequest>, NotificationInsertValidator>();
builder.Services.AddScoped<IValidator<NotificationUpdateRequest>, NotificationUpdateValidator>();
builder.Services.AddScoped<IValidator<UserNotificationInsertRequest>, UserNotificationInsertValidator>();
builder.Services.AddScoped<IValidator<UserNotificationUpdateRequest>, UserNotificationUpdateValidator>();
builder.Services.AddScoped<IValidator<CompanySettingsInsertRequest>, CompanySettingsInsertValidator>();
builder.Services.AddScoped<IValidator<CompanySettingsUpdateRequest>, CompanySettingsUpdateValidator>();
builder.Services.AddScoped<IValidator<PaymentSettingsInsertRequest>, PaymentSettingsInsertValidator>();
builder.Services.AddScoped<IValidator<PaymentSettingsUpdateRequest>, PaymentSettingsUpdateValidator>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
    app.MapGet("/", () => Results.Redirect("/scalar/v1"));
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

void AddCrud<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>(IList<TEntity> data)
    where TEntity : EntityBase
    where TSearch : BaseSearchObject
{
    builder.Services.AddScoped<IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>>(serviceProvider =>
        ActivatorUtilities.CreateInstance<InMemoryCrudService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>>(serviceProvider, data));
}
