namespace AquaFlow.Services.Payments;

// Result of IPaymentProvider.ResumeCheckoutAsync. ClientSecret/RedirectUrl are only meaningful while
// State is Open (they are what the client needs to continue paying the same attempt); a provider with
// no such flow (ManualPaymentProvider) leaves both null, same as PaymentCheckoutResult.
public sealed record PaymentResumeResult(PaymentAttemptState State, string? ClientSecret, string? RedirectUrl = null);
