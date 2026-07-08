using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRouteItemUpdateValidator : AbstractValidator<ReadingRouteItemUpdateRequest>
{
    public ReadingRouteItemUpdateValidator()
    {
        RuleFor(x => x.SortOrder).GreaterThanOrEqualTo(0);
    }
}
