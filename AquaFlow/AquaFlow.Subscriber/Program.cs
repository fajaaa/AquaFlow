using AquaFlow.Model.Messages;
using EasyNetQ;

var connectionString = Environment.GetEnvironmentVariable("RABBITMQ_CONNECTIONSTRING")
    ?? "host=localhost;username=admin;password=admin";

const string subscriptionId = "aquaflow-notification-subscriber";

using var cancellationSource = new CancellationTokenSource();
Console.CancelKeyPress += (_, args) =>
{
    args.Cancel = true;
    cancellationSource.Cancel();
};
AppDomain.CurrentDomain.ProcessExit += (_, _) => cancellationSource.Cancel();

// RabbitMQ may still be starting up when this container does (e.g. under docker compose),
// so connecting is retried with exponential backoff instead of crashing on the first attempt.
var backoff = TimeSpan.FromSeconds(1);
var maxBackoff = TimeSpan.FromSeconds(30);
IBus? bus = null;

while (bus is null && !cancellationSource.IsCancellationRequested)
{
    try
    {
        bus = RabbitHutch.CreateBus(connectionString);
        bus.PubSub.Subscribe<NotificationCreated>(subscriptionId, message =>
            Console.WriteLine($"[Notification #{message.Id}] {message.Data.Title} -> audience: {message.Data.Audience}"));
        Console.WriteLine("AquaFlow.Subscriber connected to RabbitMQ and is listening for messages. Press Ctrl+C to exit...");
    }
    catch (Exception ex)
    {
        bus?.Dispose();
        bus = null;
        Console.WriteLine($"Failed to connect/subscribe to RabbitMQ: {ex.Message}. Retrying in {backoff.TotalSeconds:0}s...");
        try
        {
            await Task.Delay(backoff, cancellationSource.Token);
        }
        catch (TaskCanceledException)
        {
            break;
        }
        backoff = TimeSpan.FromSeconds(Math.Min(backoff.TotalSeconds * 2, maxBackoff.TotalSeconds));
    }
}

try
{
    await Task.Delay(Timeout.Infinite, cancellationSource.Token);
}
catch (TaskCanceledException)
{
    // Expected on shutdown (Ctrl+C or container stop).
}

bus?.Dispose();
Console.WriteLine("AquaFlow.Subscriber is shutting down.");
