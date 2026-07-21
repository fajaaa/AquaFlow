using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class SupportTicketCreateValidator : AbstractValidator<SupportTicketCreateRequest>
{
    public SupportTicketCreateValidator()
    {
        RuleFor(x => x.Subject).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Body).NotEmpty();
    }
}
