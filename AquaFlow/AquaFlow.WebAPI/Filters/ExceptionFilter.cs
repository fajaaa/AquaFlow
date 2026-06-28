using AquaFlow.Model.Exceptions;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace AquaFlow.WebAPI.Filters;

public class ExceptionFilter : ExceptionFilterAttribute
{
    private readonly ILogger<ExceptionFilter> _logger;

    public ExceptionFilter(ILogger<ExceptionFilter> logger)
    {
        _logger = logger;
    }

    public override void OnException(ExceptionContext context)
    {
        if (context.Exception is ValidationException validationException)
        {
            foreach (var error in validationException.Errors)
            {
                context.ModelState.AddModelError(error.PropertyName ?? string.Empty, error.ErrorMessage);
            }

            context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            _logger.LogWarning(context.Exception, "Validation failed.");
        }
        else if (context.Exception is ClientException clientException)
        {
            context.ModelState.AddModelError("clientError", clientException.Message);
            context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            _logger.LogWarning("Client error: {Message}", clientException.Message);
        }
        else
        {
            context.ModelState.AddModelError("serverError", "Server side error, please check logs.");
            context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            _logger.LogError(context.Exception, "Unhandled exception.");
        }

        var errors = context.ModelState
            .Where(item => item.Value is { Errors.Count: > 0 })
            .ToDictionary(
                item => item.Key,
                item => item.Value!.Errors.Select(error => error.ErrorMessage).ToList());

        var message = errors.Values.SelectMany(value => value).FirstOrDefault()
            ?? "Request could not be processed.";

        context.Result = new JsonResult(new
        {
            message,
            errors
        });
        context.ExceptionHandled = true;
    }
}
