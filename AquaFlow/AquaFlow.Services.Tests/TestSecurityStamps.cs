using AquaFlow.Services.Database;
using Microsoft.Extensions.Caching.Memory;

namespace AquaFlow.Services.Tests;

// A real SecurityStampService over the test's context with its own fresh cache, for tests that
// construct a service depending on ISecurityStampService but don't assert on stamps themselves.
public static class TestSecurityStamps
{
    public static SecurityStampService Create(AquaFlowDbContext context, IMemoryCache? cache = null) =>
        new(context, cache ?? new MemoryCache(new MemoryCacheOptions()));
}
