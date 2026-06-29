using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using CompanySettingsCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.CompanySettingsResponse, AquaFlow.Model.SearchObjects.CompanySettingsSearchObject, AquaFlow.Model.Requests.CompanySettingsInsertRequest, AquaFlow.Model.Requests.CompanySettingsUpdateRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class CompanySettingsController : BaseCRUDController<CompanySettingsResponse, CompanySettingsSearchObject, CompanySettingsInsertRequest, CompanySettingsUpdateRequest, CompanySettingsCrudService>
{
    public CompanySettingsController(CompanySettingsCrudService service) : base(service)
    {
    }
}
