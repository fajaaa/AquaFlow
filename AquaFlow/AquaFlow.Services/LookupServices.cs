using AquaFlow.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

// Thin per-codebook services: each one only says which FK columns use its codes.

public class InvoiceStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<InvoiceStatusLookup>(dbContext, mapper)
{
    protected override async Task<bool> IsInUseAsync(string code) =>
        await DbContext.Invoices.AnyAsync(x => x.Status == code) ||
        await DbContext.InvoiceStatusHistories.AnyAsync(x => x.NewStatus == code || x.OldStatus == code);
}

public class PaymentStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<PaymentStatusLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.Payments.AnyAsync(x => x.Status == code);
}

public class PaymentMethodLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<PaymentMethodLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.Payments.AnyAsync(x => x.PaymentMethod == code);
}

public class FaultReportStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<FaultReportStatusLookup>(dbContext, mapper)
{
    protected override async Task<bool> IsInUseAsync(string code) =>
        await DbContext.FaultReports.AnyAsync(x => x.Status == code) ||
        await DbContext.FaultStatusHistories.AnyAsync(x => x.NewStatus == code || x.OldStatus == code);
}

public class WaterMeterRequestStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<WaterMeterRequestStatusLookup>(dbContext, mapper)
{
    protected override async Task<bool> IsInUseAsync(string code) =>
        await DbContext.WaterMeterRequests.AnyAsync(x => x.Status == code) ||
        await DbContext.WaterMeterRequestStatusHistories.AnyAsync(x => x.NewStatus == code || x.OldStatus == code);
}

public class WaterMeterStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<WaterMeterStatusLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.WaterMeters.AnyAsync(x => x.Status == code);
}

public class SupportTicketStatusLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<SupportTicketStatusLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.SupportTickets.AnyAsync(x => x.Status == code);
}

public class NotificationTypeLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<NotificationTypeLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.Notifications.AnyAsync(x => x.Type == code);
}

public class NotificationAudienceLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<NotificationAudienceLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.Notifications.AnyAsync(x => x.Audience == code);
}

public class ConsumptionAlertTypeLookupService(AquaFlowDbContext dbContext, IMapper mapper)
    : LookupService<ConsumptionAlertTypeLookup>(dbContext, mapper)
{
    protected override Task<bool> IsInUseAsync(string code) =>
        DbContext.WaterConsumptionAlerts.AnyAsync(x => x.AlertType == code);
}
