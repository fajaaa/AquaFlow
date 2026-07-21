using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class SupportTicketMessageCreateValidator : AbstractValidator<SupportTicketMessageCreateRequest>
{
    public SupportTicketMessageCreateValidator()
    {
        RuleFor(x => x.Body).NotEmpty();
    }
}
