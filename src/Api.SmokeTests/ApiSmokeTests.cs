/*
module: src.api.smokeTests
purpose: Verify the API host responds to a basic GET request.
exports:
  - test: ApiSmokeTests.GetApiRoot_returns_ok
patterns:
  - smoke_test
*/
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace ProjectArchitecture.Api.SmokeTests;

public sealed class ApiSmokeTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ApiSmokeTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Test");
        });
    }

    [Fact]
    public async Task GetApiRoot_returns_ok()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
