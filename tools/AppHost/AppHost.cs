/*
module: tools.appHost
purpose: Compose the Aspire distributed application for local development.
exports:
  - entrypoint: AppHost
patterns:
  - aspire_apphost
*/
var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.ProjectArchitecture_Api>("api");
builder.AddProject<Projects.ProjectArchitecture_Worker>("worker");

builder.Build().Run();
