using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class DeviceTokenRegisterValidator : AbstractValidator<DeviceTokenRegisterRequest>
{
    public DeviceTokenRegisterValidator()
    {
        RuleFor(x => x.Token).NotEmpty();
        RuleFor(x => x.Platform)
            .NotEmpty()
            .Must(platform => platform.Equals("android", StringComparison.OrdinalIgnoreCase)
                || platform.Equals("ios", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Platform must be 'android' or 'ios'.");
    }
}
