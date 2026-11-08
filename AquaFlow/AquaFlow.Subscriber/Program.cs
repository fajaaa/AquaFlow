using Microsoft.Extensions.Hosting;
using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Services;
using AquaFlow.Services.Database;
using AquaFlow.Subscriber;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

// Same convention as AquaFlow.WebAPI: load a developer-local .env into process environment
// variables before configuration is built.
DotNetEnv.Env.Load();

var builder = Host.CreateApplicationBuilder(args);

var connectionString = builder.Configuration["ConnectionStrings:DefaultConnection"];
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Connection string 'DefaultConnection' is required. " +
        "Set it with the ConnectionStrings__DefaultConnection environment variable.");
}

var rabbitMqConnectionString = builder.Configuration["RabbitMQ:ConnectionString"]
    ?? Environment.GetEnvironmentVariable("RABBITMQ_CONNECTIONSTRING")
    ?? "host=localhost;username=admin;password=admin";

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddDbContext<AquaFlowDbContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddFirebasePush(builder.Configuration);
builder.Services.AddScoped<NotificationPushDispatcher>();
builder.Services.AddScoped<NotificationPushHandler>();
builder.Services.AddSingleton<IBus>(_ => RabbitHutch.CreateBus(rabbitMqConnectionString));
builder.Services.AddHostedService<NotificationPushWorker>();

await builder.Build().RunAsync();
