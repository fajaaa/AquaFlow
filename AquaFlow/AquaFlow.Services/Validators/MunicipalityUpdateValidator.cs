using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MunicipalityUpdateValidator : AbstractValidator<MunicipalityUpdateRequest>
{
    public MunicipalityUpdateValidator()
    {
        Include(new MunicipalityInsertValidator());
    }
}
