using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Responses;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services;
using FluentValidation;
using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.WebAPI.Controllers;

public abstract class BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest, TService>
    : BaseReadController<TResponse, TSearch, TService>
    where TResponse : AuditableResponse
    where TSearch : BaseSearchObject
    where TService : IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest, TPatchRequest>
{
    protected BaseCRUDController(TService service) : base(service)
    {
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TResponse>> Create([FromBody] TInsertRequest request)
    {
        try
        {
            var result = await Service.InsertAsync(request);

            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }
        catch (ValidationException exception)
        {
            return BadRequest(CreateValidationErrorResponse(exception));
        }
        catch (ClientException exception)
        {
            return BadRequest(CreateClientErrorResponse(exception));
        }
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdateRequest request)
    {
        try
        {
            var result = await Service.UpdateAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ValidationException exception)
        {
            return BadRequest(CreateValidationErrorResponse(exception));
        }
        catch (ClientException exception)
        {
            return BadRequest(CreateClientErrorResponse(exception));
        }
    }

    [HttpPatch("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TResponse>> Patch(int id, [FromBody] TPatchRequest request)
    {
        try
        {
            var result = await Service.PatchAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ValidationException exception)
        {
            return BadRequest(CreateValidationErrorResponse(exception));
        }
        catch (ClientException exception)
        {
            return BadRequest(CreateClientErrorResponse(exception));
        }
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await Service.DeleteAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (DbUpdateException exception) when (IsForeignKeyConstraintException(exception))
        {
            return BadRequest(CreateForeignKeyErrorResponse("Cannot delete resource because it has related records."));
        }
    }

    private static object CreateValidationErrorResponse(ValidationException exception)
    {
        var errors = exception.Errors
            .GroupBy(error => error.PropertyName ?? string.Empty)
            .ToDictionary(
                group => group.Key,
                group => group.Select(error => error.ErrorMessage).ToList());

        var message = errors.Values.SelectMany(value => value).FirstOrDefault()
            ?? "Validation failed.";

        return new
        {
            message,
            errors
        };
    }

    private static object CreateClientErrorResponse(ClientException exception)
    {
        return new
        {
            message = exception.Message,
            errors = new Dictionary<string, List<string>>
            {
                ["clientError"] = new() { exception.Message }
            }
        };
    }

    private static object CreateForeignKeyErrorResponse(string message)
    {
        return new
        {
            message,
            errors = new Dictionary<string, List<string>>
            {
                ["foreignKey"] = new() { message }
            }
        };
    }

    private static bool IsForeignKeyConstraintException(DbUpdateException exception)
    {
        return exception.InnerException is SqlException sqlException &&
            sqlException.Number == 547 &&
            (sqlException.Message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase) ||
                sqlException.Message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase));
    }
}
