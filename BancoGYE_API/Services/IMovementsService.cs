using BancoGYE_API.DTOs;

namespace BancoGYE_API.Services;

public interface IMovementsService
{
    PagedResponse<MovementResponse> GetMovements(MovementsQueryRequest query);
    MovementDetailResponse? GetMovementById(Guid id);
}
