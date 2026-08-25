using AquaFlow.Model.Responses;
using AquaFlow.WebAPI.Controllers;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace AquaFlow.WebAPI.Tests.Dashboard;

public class DashboardControllerTests
{
    private static readonly DateTime From = new(2026, 1, 1);
    private static readonly DateTime To = new(2026, 6, 1);
    private const int CityId = 1;

    [Fact]
    public async Task GetRevenueTrend_ReturnsServiceResultAndForwardsFilters()
    {
        var service = new FakeDashboardService
        {
            TrendResult = new List<DashboardTrendPointResponse> { new() { PeriodStart = From, Value = 123 } },
        };
        var controller = new DashboardController(service);

        var result = await controller.GetRevenueTrend(From, To, CityId);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var body = Assert.IsType<List<DashboardTrendPointResponse>>(ok.Value);
        Assert.Same(service.TrendResult, body);
        Assert.Equal((From, To, CityId), service.LastCall);
    }

    [Fact]
    public async Task GetInvoiceStatusBreakdown_ReturnsServiceResult()
    {
        var service = new FakeDashboardService
        {
            BreakdownResult = new List<DashboardStatusBreakdownResponse> { new() { Status = "Issued", Count = 3, TotalAmount = 90 } },
        };
        var controller = new DashboardController(service);

        var result = await controller.GetInvoiceStatusBreakdown(From, To, CityId);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Same(service.BreakdownResult, ok.Value);
    }

    [Fact]
    public async Task GetConsumptionTrend_ReturnsServiceResult()
    {
        var service = new FakeDashboardService();
        var controller = new DashboardController(service);

        var result = await controller.GetConsumptionTrend(null, null, null);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal((null, null, null), service.LastCall);
    }

    [Fact]
    public async Task GetFaultReportStatusBreakdown_ReturnsServiceResult()
    {
        var service = new FakeDashboardService();
        var controller = new DashboardController(service);

        var result = await controller.GetFaultReportStatusBreakdown(From, To, null);

        Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal((From, To, (int?)null), service.LastCall);
    }

    [Fact]
    public async Task GetUserGrowthTrend_ReturnsServiceResult()
    {
        var service = new FakeDashboardService();
        var controller = new DashboardController(service);

        var result = await controller.GetUserGrowthTrend(From, To, CityId);

        Assert.IsType<OkObjectResult>(result.Result);
    }

    [Fact]
    public async Task GetWaterMeterRequestStatusBreakdown_ReturnsServiceResult()
    {
        var service = new FakeDashboardService();
        var controller = new DashboardController(service);

        var result = await controller.GetWaterMeterRequestStatusBreakdown(From, To, CityId);

        Assert.IsType<OkObjectResult>(result.Result);
    }
}
