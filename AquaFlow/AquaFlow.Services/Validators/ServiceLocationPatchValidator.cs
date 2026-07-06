using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ServiceLocationPatchValidator : AbstractValidator<ServiceLocationPatchRequest>
{
    public ServiceLocationPatchValidator()
    {
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.Address).NotEmpty().MaximumLength(200).When(x => x.Address != null);
        RuleFor(x => x.LocationType).NotEmpty().MaximumLength(50).When(x => x.LocationType != null);
        RuleFor(x => x.Latitude).InclusiveBetween(-90m, 90m).When(x => x.Latitude.HasValue);
        RuleFor(x => x.Longitude).InclusiveBetween(-180m, 180m).When(x => x.Longitude.HasValue);
    }
}
