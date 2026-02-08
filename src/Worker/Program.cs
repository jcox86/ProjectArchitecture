/*
module: src.worker
purpose: Configure the background worker host and dependencies.
exports:
  - host: WorkerHost
patterns:
  - background_service
*/
using ProjectArchitecture.Infrastructure;
using ProjectArchitecture.Worker;
using Serilog;

var builder = Host.CreateApplicationBuilder(args);

try
{
    // Register any hosted services here
    builder.AddServiceDefaults();
    builder.Services.AddInfrastructure(builder.Configuration);
    builder.Services.Configure<OutboxDispatcherOptions>(builder.Configuration.GetSection(OutboxDispatcherOptions.SectionName));
    builder.Services.Configure<QueueProcessorOptions>(builder.Configuration.GetSection(QueueProcessorOptions.SectionName));
    builder.Services.AddHostedService<Worker>();
    builder.Services.AddHostedService<StorageQueueProcessor>();

    var host = builder.Build();

    host.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Worker host terminated unexpectedly.");
}
finally
{
    Log.Information("Worker stopped");
    Log.CloseAndFlush();
}
