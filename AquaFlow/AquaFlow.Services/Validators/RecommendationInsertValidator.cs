using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class RecommendationInsertValidator : AbstractValidator<RecommendationInsertRequest>
{
    public RecommendationInsertValidator()
    {
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.Type).NotEmpty().MaximumLength(60);
    }
}
