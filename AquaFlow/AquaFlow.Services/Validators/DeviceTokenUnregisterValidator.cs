using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class DeviceTokenUnregisterValidator : AbstractValidator<DeviceTokenUnregisterRequest>
{
    public DeviceTokenUnregisterValidator()
    {
        RuleFor(x => x.Token).NotEmpty();
    }
}
