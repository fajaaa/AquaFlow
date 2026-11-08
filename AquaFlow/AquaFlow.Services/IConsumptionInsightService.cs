using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

public interface IConsumptionInsightService
{
    // Throws KeyNotFoundException when the meter does not exist.
    Task<ConsumptionInsightResponse> GetForWaterMeterAsync(int waterMeterId);

    // Owning customer profile id of the meter, or null when the meter does not exist - lets the
    // controller enforce customer ownership without loading the whole insight first.
    Task<int?> GetOwnerCustomerIdAsync(int waterMeterId);
}
