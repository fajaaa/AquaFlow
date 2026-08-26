namespace AquaFlow.Common.Services.MessageBus;

public interface IMessagePublisher
{
    Task PublishAsync<T>(T message) where T : class;
}
