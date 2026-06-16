using BancoGYE_API.DTOs;
using BancoGYE_API.Models;
using BancoGYE_API.Repositories;

namespace BancoGYE_API.Services;

public class MovementsService : IMovementsService
{
    private readonly IMovementsRepository _repository;

    public MovementsService(IMovementsRepository repository)
    {
        _repository = repository;
    }

    public PagedResponse<MovementResponse> GetMovements(MovementsQueryRequest query)
    {
        var pageSize = Math.Clamp(query.PageSize, 1, 100);
        var page = Math.Max(query.Page, 1);

        var (items, total) = _repository.GetPaged(page, pageSize, query.From, query.To, query.Search);

        var responses = items.Select(MapToResponse);

        return new PagedResponse<MovementResponse>(
            Items: responses,
            Page: page,
            PageSize: pageSize,
            TotalCount: total,
            HasMore: page * pageSize < total
        );
    }

    public MovementDetailResponse? GetMovementById(Guid id)
    {
        var movement = _repository.GetById(id);
        if (movement is null) return null;

        return new MovementDetailResponse(
            movement.Id,
            movement.Reference,
            movement.Description,
            movement.ContactName,
            movement.Amount,
            movement.Type.ToString(),
            movement.Status.ToString(),
            movement.Date,
            movement.Notes
        );
    }

    private static MovementResponse MapToResponse(Movement m) => new(
        m.Id,
        m.Reference,
        m.Description,
        m.ContactName,
        m.Amount,
        m.Type.ToString(),
        m.Status.ToString(),
        m.Date,
        m.Notes
    );
}
