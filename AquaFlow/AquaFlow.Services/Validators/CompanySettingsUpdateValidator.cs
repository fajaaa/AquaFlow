using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CompanySettingsUpdateValidator : AbstractValidator<CompanySettingsUpdateRequest>
{
    public CompanySettingsUpdateValidator()
    {
        Include(new CompanySettingsInsertValidator());
    }
}
