using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRouteItemPatchValidator : AbstractValidator<ReadingRouteItemPatchRequest>
{
    public ReadingRouteItemPatchValidator()
    {
        RuleFor(x => x.SortOrder).GreaterThanOrEqualTo(0).When(x => x.SortOrder.HasValue);
    }
}
