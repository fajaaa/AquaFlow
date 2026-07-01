using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class InvoiceService
    : EfCrudService<Invoice, InvoiceResponse, InvoiceSearchObject, InvoiceInsertRequest, InvoiceUpdateRequest, InvoicePatchRequest>,
      IInvoiceService
{
    private readonly AquaFlowDbContext _dbContext;
    private readonly BaseInvoiceState _invoiceState;

    public InvoiceService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<InvoiceInsertRequest>> insertValidators,
        IEnumerable<IValidator<InvoiceUpdateRequest>> updateValidators,
        IEnumerable<IValidator<InvoicePatchRequest>> patchValidators,
        BaseInvoiceState invoiceState)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _invoiceState = invoiceState;
    }

    // New invoices always start in Draft; every later status change goes through the state machine.
    protected override Task BeforeInsertAsync(InvoiceInsertRequest request)
    {
        request.Status = InvoiceStatus.Draft;
        return Task.CompletedTask;
    }

    public async Task<InvoiceResponse> IssueAsync(int id, int changedById)
    {
        var state = await ResolveStateAsync(id);
        return await state.IssueAsync(id, changedById);
    }

    public async Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
    {
        var state = await ResolveStateAsync(id);
        return await state.RecordPaymentAsync(id, amount, changedById);
    }

    public async Task<InvoiceResponse> CancelAsync(int id, int changedById)
    {
        var state = await ResolveStateAsync(id);
        return await state.CancelAsync(id, changedById);
    }

    public async Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById)
    {
        var state = await ResolveStateAsync(id);
        return await state.MarkOverdueAsync(id, changedById);
    }

    public async Task<List<string>> GetAllowedActionsAsync(int id)
    {
        var status = await GetStatusAsync(id);
        return _invoiceState.GetState(status).GetAllowedActions();
    }

    private async Task<BaseInvoiceState> ResolveStateAsync(int id)
    {
        var status = await GetStatusAsync(id);
        return _invoiceState.GetState(status);
    }

    private async Task<string> GetStatusAsync(int id)
    {
        var status = await _dbContext.Invoices
            .Where(invoice => invoice.Id == id)
            .Select(invoice => invoice.Status)
            .FirstOrDefaultAsync();
        if (status == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return status;
    }
}
