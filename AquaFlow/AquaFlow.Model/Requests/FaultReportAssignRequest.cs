namespace AquaFlow.Model.Requests;

public class FaultReportAssignRequest
{
    public int CollectorId { get; set; }
    // Optional reason/instruction for the assignment; recorded in the FaultStatusHistory note.
    public string? Note { get; set; }
}
