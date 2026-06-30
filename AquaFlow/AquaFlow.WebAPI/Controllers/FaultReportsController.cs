using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

using FaultReportCrudService = AquaFlow.Services.IBaseCRUDService<AquaFlow.Model.Responses.FaultReportResponse, AquaFlow.Model.SearchObjects.FaultReportSearchObject, AquaFlow.Model.Requests.FaultReportInsertRequest, AquaFlow.Model.Requests.FaultReportUpdateRequest, AquaFlow.Model.Requests.FaultReportPatchRequest>;

namespace AquaFlow.WebAPI.Controllers;

public class FaultReportsController : BaseCRUDController<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest, FaultReportCrudService>
{
    public FaultReportsController(FaultReportCrudService service) : base(service)
    {
    }
}
