using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRouteUpdateValidator : AbstractValidator<ReadingRouteUpdateRequest>
{
    public ReadingRouteUpdateValidator()
    {
        Include(new ReadingRouteInsertValidator());
    }
}
