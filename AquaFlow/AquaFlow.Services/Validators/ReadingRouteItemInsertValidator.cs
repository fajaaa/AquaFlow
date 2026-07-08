using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRouteItemInsertValidator : AbstractValidator<ReadingRouteItemInsertRequest>
{
    public ReadingRouteItemInsertValidator()
    {
        RuleFor(x => x.ReadingRouteId).GreaterThan(0);
        RuleFor(x => x.WaterMeterId).GreaterThan(0);
        RuleFor(x => x.SortOrder).GreaterThanOrEqualTo(0);
    }
}
