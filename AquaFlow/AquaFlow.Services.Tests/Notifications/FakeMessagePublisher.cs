using AquaFlow.Common.Services.MessageBus;

namespace AquaFlow.Services.Tests.Notifications;

public class FakeMessagePublisher : IMessagePublisher
{
    public List<PublishCall> Calls { get; } = new();
    public Exception? ExceptionToThrow { get; set; }

    public Task PublishAsync<T>(T message) where T : class
    {
        if (ExceptionToThrow is not null)
        {
            throw ExceptionToThrow;
        }

        Calls.Add(new PublishCall(typeof(T), message));

        return Task.CompletedTask;
    }

    public record PublishCall(Type MessageType, object Message);
}
