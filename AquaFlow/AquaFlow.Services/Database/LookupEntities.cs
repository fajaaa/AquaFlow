namespace AquaFlow.Services.Database;

// Concrete codebook tables (table names are set in AquaFlowDbContext.ConfigureLookups). The
// "Lookup" suffix avoids clashing with the constant classes (InvoiceStatus, PaymentStatus, ...).
public class InvoiceStatusLookup : LookupEntityBase { }
public class PaymentStatusLookup : LookupEntityBase { }
public class PaymentMethodLookup : LookupEntityBase { }
public class FaultReportStatusLookup : LookupEntityBase { }
public class WaterMeterRequestStatusLookup : LookupEntityBase { }
public class WaterMeterStatusLookup : LookupEntityBase { }
public class SupportTicketStatusLookup : LookupEntityBase { }
public class NotificationTypeLookup : LookupEntityBase { }
public class ConsumptionAlertTypeLookup : LookupEntityBase { }
public class NotificationAudienceLookup : LookupEntityBase { }
