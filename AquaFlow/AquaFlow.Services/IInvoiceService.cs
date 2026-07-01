using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

public interface IInvoiceService
    : IBaseCRUDService<InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>
{
    Task<InvoiceResponse> IssueAsync(int id, int changedById);
    Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById);
    Task<InvoiceResponse> CancelAsync(int id, int changedById);
    Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);
}
