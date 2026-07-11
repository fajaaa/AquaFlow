using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;

namespace AquaFlow.Services;

// Minimal projection for the photo sub-routes' ownership checks (Upload/GetPhotos/GetPhoto/
// DeletePhoto): just the columns those routes need, without the Customer/Settlement joins
// GetByIdAsync's IncludeForRead pulls in for the full FaultReportResponse. AssignedCollectorId
// lets the photo READ routes grant the assigned collector access without a second query.
public record FaultReportOwnership(int CustomerId, string Status, int? AssignedCollectorId);

public interface IFaultReportService
    : IBaseCRUDService<FaultReportResponse, FaultReportSearchObject, FaultReportInsertRequest, FaultReportUpdateRequest, FaultReportPatchRequest>
{
    // Returns null (rather than throwing, unlike GetByIdAsync) when no report with this id exists -
    // every caller here immediately turns that into a 404, so there's no need for exception-based
    // control flow.
    Task<FaultReportOwnership?> GetOwnershipAsync(int id);

    // State-machine transitions (see AquaFlow.Services/FaultReportStateMachine): each loads the
    // tracked entity once, resolves the state from its Status, and delegates to the state action.
    // changedById is the acting user stamped onto the FaultStatusHistory row. AssignAsync also
    // validates the target CollectorProfile exists and its linked user is active; the optional
    // note is the admin's reason, recorded in the FaultStatusHistory note.
    Task<FaultReportResponse> AssignAsync(int id, int collectorId, string? note, int changedById);
    Task<FaultReportResponse> StartAsync(int id, int changedById);
    Task<FaultReportResponse> ResolveAsync(int id, int changedById);
    Task<List<string>> GetAllowedActionsAsync(int id);
}
