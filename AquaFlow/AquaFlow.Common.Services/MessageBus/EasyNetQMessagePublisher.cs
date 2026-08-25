using EasyNetQ;

namespace AquaFlow.Common.Services.MessageBus;

public class EasyNetQMessagePublisher : IMessagePublisher
{
    private readonly IBus _bus;

    public EasyNetQMessagePublisher(IBus bus)
    {
        _bus = bus;
    }

    public Task PublishAsync<T>(T message) where T : class
    {
        return _bus.PubSub.PublishAsync(message);
    }
}
