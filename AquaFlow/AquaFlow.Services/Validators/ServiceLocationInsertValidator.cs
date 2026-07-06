using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ServiceLocationInsertValidator : AbstractValidator<ServiceLocationInsertRequest>
{
    public ServiceLocationInsertValidator()
    {
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.SettlementId).GreaterThan(0);
        RuleFor(x => x.Address).NotEmpty().MaximumLength(200);
        RuleFor(x => x.LocationType).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Latitude).InclusiveBetween(-90m, 90m).When(x => x.Latitude.HasValue);
        RuleFor(x => x.Longitude).InclusiveBetween(-180m, 180m).When(x => x.Longitude.HasValue);
    }
}
