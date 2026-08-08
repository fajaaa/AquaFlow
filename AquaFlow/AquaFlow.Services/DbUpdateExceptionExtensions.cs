using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public static class DbUpdateExceptionExtensions
{
    private const int UniqueIndexViolation = 2601;
    private const int UniqueConstraintViolation = 2627;

    // Used to tell a genuine data problem apart from a benign race against another
    // request that already inserted the same row (see callers for the concrete scenario).
    public static bool IsDuplicateKeyViolation(this DbUpdateException exception)
    {
        return exception.InnerException is SqlException sqlException &&
            (sqlException.Number == UniqueIndexViolation || sqlException.Number == UniqueConstraintViolation);
    }
}
