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
    private readonly IInvoiceStateResolver _stateResolver;

    public InvoiceService(
        AquaFlowDbContext dbContext,
        IMapper mapper,
        IEnumerable<IValidator<InvoiceInsertRequest>> insertValidators,
        IEnumerable<IValidator<InvoiceUpdateRequest>> updateValidators,
        IEnumerable<IValidator<InvoicePatchRequest>> patchValidators,
        IInvoiceStateResolver stateResolver)
        : base(dbContext, mapper, insertValidators, updateValidators, patchValidators)
    {
        _dbContext = dbContext;
        _stateResolver = stateResolver;
    }

    // New invoices always start in Draft; every later status change goes through the state machine.
    protected override Task BeforeInsertAsync(InvoiceInsertRequest request)
    {
        request.Status = InvoiceStatus.Draft;
        return Task.CompletedTask;
    }

    public async Task<InvoiceResponse> IssueAsync(int id, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).IssueAsync(invoice, changedById);
    }

    public async Task<InvoiceResponse> RecordPaymentAsync(int id, decimal amount, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).RecordPaymentAsync(invoice, amount, changedById);
    }

    public async Task<InvoiceResponse> CancelAsync(int id, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).CancelAsync(invoice, changedById);
    }

    public async Task<InvoiceResponse> MarkOverdueAsync(int id, int changedById)
    {
        var invoice = await LoadInvoiceAsync(id);
        return await _stateResolver.Resolve(invoice.Status).MarkOverdueAsync(invoice, changedById);
    }

    public async Task<List<string>> GetAllowedActionsAsync(int id)
    {
        // Read-only lookup: only the status is needed to resolve the state, so avoid loading (and
        // tracking) the whole entity here.
        var status = await _dbContext.Invoices
            .Where(invoice => invoice.Id == id)
            .Select(invoice => invoice.Status)
            .FirstOrDefaultAsync();
        if (status == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return _stateResolver.Resolve(status).GetAllowedActions();
    }

    // Loads the tracked Invoice once so the resolved state can both resolve from Status and mutate the
    // same entity, or throws 404 when it does not exist. This replaces the former two-query path
    // (status-only read to resolve the state, then a second full read inside the state).
    private async Task<Invoice> LoadInvoiceAsync(int id)
    {
        var invoice = await _dbContext.Invoices.FirstOrDefaultAsync(invoice => invoice.Id == id);
        if (invoice == null)
        {
            throw new KeyNotFoundException($"Invoice with id {id} was not found.");
        }

        return invoice;
    }
}
