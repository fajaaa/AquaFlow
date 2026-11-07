using AquaFlow.Services.Forecasting;
using Xunit;
using Rules = AquaFlow.Services.Forecasting.ConsumptionRecommendationRules;

namespace AquaFlow.Services.Tests.Forecasting;

public class ConsumptionRecommendationRulesTests
{
    // A healthy meter: enough data, forecast equal to the recent average, no alert, no settlement data.
    private static Rules.Input Healthy(
        decimal average = 10m,
        decimal predicted = 10m,
        decimal? settlementAverage = null,
        Rules.OpenAlertInput? alert = null,
        decimal? estimatedAmount = null,
        bool hasEnoughData = true,
        int readingsCount = 8) =>
        new(hasEnoughData, readingsCount, average, predicted, predicted - 1m, predicted + 1m, estimatedAmount, settlementAverage, alert);

    [Fact]
    public void Evaluate_OpenAlertAboveExpected_ReturnsLeakSuspectedWithAllNumbers()
    {
        var alert = new Rules.OpenAlertInput(Measured: 60m, Expected: 10m, Lower: 8m, Upper: 12m, Baseline: 11m);

        var items = Rules.Evaluate(Healthy(alert: alert));

        var item = Assert.Single(items, i => i.Code == Rules.LeakSuspected);
        Assert.Equal("warning", item.Severity);
        Assert.Equal(60m, item.Parameters["measured"]);
        Assert.Equal(10m, item.Parameters["expected"]);
        Assert.Equal(8m, item.Parameters["lower"]);
        Assert.Equal(12m, item.Parameters["upper"]);
        Assert.Equal(11m, item.Parameters["baseline"]);
        Assert.DoesNotContain(items, i => i.Code == Rules.MeterCheckSuggested);
    }

    [Fact]
    public void Evaluate_OpenAlertBelowExpected_ReturnsMeterCheckSuggested()
    {
        var alert = new Rules.OpenAlertInput(Measured: 1m, Expected: 10m, Lower: 8m, Upper: 12m, Baseline: 11m);

        var items = Rules.Evaluate(Healthy(alert: alert));

        var item = Assert.Single(items, i => i.Code == Rules.MeterCheckSuggested);
        Assert.Equal("warning", item.Severity);
        Assert.DoesNotContain(items, i => i.Code == Rules.LeakSuspected);
    }

    [Fact]
    public void Evaluate_OpenAlertWithoutExpectation_ComparesAgainstBaselineAndOmitsMissingParameters()
    {
        var above = Rules.Evaluate(Healthy(alert: new Rules.OpenAlertInput(50m, null, null, null, 20m)));
        var below = Rules.Evaluate(Healthy(alert: new Rules.OpenAlertInput(5m, null, null, null, 20m)));

        var leak = Assert.Single(above, i => i.Code == Rules.LeakSuspected);
        Assert.False(leak.Parameters.ContainsKey("expected"));
        Assert.False(leak.Parameters.ContainsKey("lower"));
        Assert.False(leak.Parameters.ContainsKey("upper"));
        Assert.Equal(20m, leak.Parameters["baseline"]);
        Assert.Contains(below, i => i.Code == Rules.MeterCheckSuggested);
    }

    [Fact]
    public void Evaluate_OpenAlertEqualToReference_FiresNeitherAlertRule()
    {
        var items = Rules.Evaluate(Healthy(alert: new Rules.OpenAlertInput(10m, 10m, 8m, 12m, 10m)));

        Assert.DoesNotContain(items, i => i.Code is Rules.LeakSuspected or Rules.MeterCheckSuggested);
    }

    [Fact]
    public void Evaluate_ForecastExactlyFifteenPercentAbove_DoesNotFire()
    {
        var items = Rules.Evaluate(Healthy(average: 10m, predicted: 11.5m));

        Assert.DoesNotContain(items, i => i.Code == Rules.ForecastAboveAverage);
        Assert.Equal(Rules.OnTrack, Assert.Single(items).Code);
    }

    [Fact]
    public void Evaluate_ForecastJustOverFifteenPercent_IsInfoWithExplanation()
    {
        var items = Rules.Evaluate(Healthy(average: 10m, predicted: 11.6m, estimatedAmount: 21.46m));

        var item = Assert.Single(items, i => i.Code == Rules.ForecastAboveAverage);
        Assert.Equal("info", item.Severity);
        Assert.Equal(11.6m, item.Parameters["predicted"]);
        Assert.Equal(10.6m, item.Parameters["lower"]);
        Assert.Equal(12.6m, item.Parameters["upper"]);
        Assert.Equal(10m, item.Parameters["average"]);
        Assert.Equal(16m, item.Parameters["percentAbove"]);
        Assert.Equal(21.46m, item.Parameters["estimatedAmount"]);
    }

    [Fact]
    public void Evaluate_ForecastExactlyThirtyPercentAbove_StaysInfo_AboveThirtyIsWarning()
    {
        var atBoundary = Rules.Evaluate(Healthy(average: 10m, predicted: 13m));
        var over = Rules.Evaluate(Healthy(average: 10m, predicted: 13.1m));

        Assert.Equal("info", Assert.Single(atBoundary, i => i.Code == Rules.ForecastAboveAverage).Severity);
        Assert.Equal("warning", Assert.Single(over, i => i.Code == Rules.ForecastAboveAverage).Severity);
    }

    [Fact]
    public void Evaluate_ForecastAboveAverageWithoutTariff_OmitsEstimatedAmount()
    {
        var items = Rules.Evaluate(Healthy(average: 10m, predicted: 14m, estimatedAmount: null));

        var item = Assert.Single(items, i => i.Code == Rules.ForecastAboveAverage);
        Assert.False(item.Parameters.ContainsKey("estimatedAmount"));
    }

    [Fact]
    public void Evaluate_ZeroRecentAverage_NeverDividesByZero()
    {
        var items = Rules.Evaluate(Healthy(average: 0m, predicted: 5m, settlementAverage: 0m));

        Assert.DoesNotContain(items, i => i.Code is Rules.ForecastAboveAverage or Rules.AboveSettlementAverage);
    }

    [Fact]
    public void Evaluate_AverageExactlyTwentyPercentAboveSettlement_DoesNotFire()
    {
        var items = Rules.Evaluate(Healthy(average: 12m, predicted: 12m, settlementAverage: 10m));

        Assert.DoesNotContain(items, i => i.Code == Rules.AboveSettlementAverage);
    }

    [Fact]
    public void Evaluate_AverageOverTwentyPercentAboveSettlement_ReturnsInfoWithNumbers()
    {
        var items = Rules.Evaluate(Healthy(average: 15m, predicted: 15m, settlementAverage: 10m));

        var item = Assert.Single(items, i => i.Code == Rules.AboveSettlementAverage);
        Assert.Equal("info", item.Severity);
        Assert.Equal(15m, item.Parameters["average"]);
        Assert.Equal(10m, item.Parameters["settlementAverage"]);
        Assert.Equal(50m, item.Parameters["percentAbove"]);
        Assert.DoesNotContain(items, i => i.Code == Rules.OnTrack);
    }

    [Fact]
    public void Evaluate_NoSettlementAverage_SkipsSettlementRule()
    {
        var items = Rules.Evaluate(Healthy(average: 100m, predicted: 100m, settlementAverage: null));

        Assert.DoesNotContain(items, i => i.Code == Rules.AboveSettlementAverage);
    }

    [Fact]
    public void Evaluate_NothingFires_ReturnsOnlyOnTrack()
    {
        var items = Rules.Evaluate(Healthy(average: 10m, predicted: 10m, settlementAverage: 10m));

        var item = Assert.Single(items);
        Assert.Equal(Rules.OnTrack, item.Code);
        Assert.Equal("positive", item.Severity);
    }

    [Fact]
    public void Evaluate_NotEnoughData_ReturnsOnlyNotEnoughDataWithCounts()
    {
        var items = Rules.Evaluate(Healthy(hasEnoughData: false, readingsCount: 3, average: 10m, predicted: 0m));

        var item = Assert.Single(items);
        Assert.Equal(Rules.NotEnoughData, item.Code);
        Assert.Equal("info", item.Severity);
        Assert.Equal(3m, item.Parameters["readingsCount"]);
        Assert.Equal(5m, item.Parameters["required"]);
    }

    [Fact]
    public void Evaluate_NotEnoughDataButOpenAlert_StillReportsAlertBeforeNotEnoughData()
    {
        var items = Rules.Evaluate(Healthy(hasEnoughData: false, readingsCount: 3, alert: new Rules.OpenAlertInput(50m, null, null, null, 10m)));

        Assert.Equal([Rules.LeakSuspected, Rules.NotEnoughData], items.Select(i => i.Code));
    }

    [Fact]
    public void Evaluate_MultipleRules_AreOrderedWarningThenInfoThenPositive()
    {
        var items = Rules.Evaluate(Healthy(
            average: 10m,
            predicted: 14m, // +40 % -> warning
            settlementAverage: 5m, // average 100 % above -> info
            alert: new Rules.OpenAlertInput(60m, 10m, 8m, 12m, 10m)));

        Assert.Equal(
            [Rules.LeakSuspected, Rules.ForecastAboveAverage, Rules.AboveSettlementAverage],
            items.Select(i => i.Code));
        Assert.Equal(["warning", "warning", "info"], items.Select(i => i.Severity));
        Assert.DoesNotContain(items, i => i.Code == Rules.OnTrack);
    }

    [Fact]
    public void Evaluate_InfoForecastAndWarningAlert_PutsWarningFirstDespiteRuleOrder()
    {
        var items = Rules.Evaluate(Healthy(
            average: 10m,
            predicted: 12m, // +20 % -> info
            alert: new Rules.OpenAlertInput(1m, 10m, 8m, 12m, 10m)));

        Assert.Equal([Rules.MeterCheckSuggested, Rules.ForecastAboveAverage], items.Select(i => i.Code));
    }
}
