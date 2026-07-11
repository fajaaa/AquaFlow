using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

// Minimal projection for the photo sub-routes' ownership checks (Upload/GetPhotos/GetPhoto/
// DeletePhoto): just the two columns those routes need, without the Customer/Settlement joins
// GetByIdAsync's IncludeForRead pulls in for the full FaultReportResponse.
public record FaultReportOwnership(int CustomerId, string Status);

public interface IFaultReportService
    : IBaseCRUDService<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>
{
    // Returns null (rather than throwing, unlike GetByIdAsync) when no report with this id exists -
    // every caller here immediately turns that into a 404, so there's no need for exception-based
    // control flow.
    Task<FaultReportOwnership?> GetOwnershipAsync(int id);

    // State-machine transitions (see AquaFlow.Services/FaultReportStateMachine): each loads the
    // tracked entity once, resolves the state from its Status, and delegates to the state action.
    // changedById is the acting user stamped onto the FaultStatusHistory row.
    Task<FaultReportResponse> StartAsync(int id, int changedById);
    Task<FaultReportResponse> ResolveAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);
}
