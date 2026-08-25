using AquaFlow.Model.Messages;
using EasyNetQ;

var connectionString = Environment.GetEnvironmentVariable("RABBITMQ_CONNECTIONSTRING")
    ?? "host=localhost;username=admin;password=admin";

var bus = RabbitHutch.CreateBus(connectionString);

const string subscriptionId = "aquaflow-notification-subscriber";

bus.PubSub.Subscribe<NotificationCreated>(subscriptionId, message =>
    Console.WriteLine($"[Notification #{message.Id}] {message.Data.Title} -> audience: {message.Data.Audience}"));

Console.WriteLine("AquaFlow.Subscriber is listening for messages. Press Ctrl+C or any key to exit...");
Console.ReadKey();
