using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ServiceLocationUpdateValidator : AbstractValidator<ServiceLocationUpdateRequest>
{
    public ServiceLocationUpdateValidator()
    {
        Include(new ServiceLocationInsertValidator());
    }
}
