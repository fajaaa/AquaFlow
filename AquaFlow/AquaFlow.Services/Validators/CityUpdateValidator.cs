using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CityUpdateValidator : AbstractValidator<CityUpdateRequest>
{
    public CityUpdateValidator()
    {
        Include(new CityInsertValidator());
    }
}
