namespace BancoGYE_API.DTOs;

public record MovementResponse(
    Guid Id,
    string Reference,
    string Description,
    string ContactName,
    decimal Amount,
    string Type,
    string Status,
    DateTime Date,
    string? Notes
);

public record MovementDetailResponse(
    Guid Id,
    string Reference,
    string Description,
    string ContactName,
    decimal Amount,
    string Type,
    string Status,
    DateTime Date,
    string? Notes
);

public record PagedResponse<T>(
    IEnumerable<T> Items,
    int Page,
    int PageSize,
    int TotalCount,
    bool HasMore
);

public record MovementsQueryRequest(
    int Page = 1,
    int PageSize = 20,
    DateTime? From = null,
    DateTime? To = null,
    string? Search = null
);
