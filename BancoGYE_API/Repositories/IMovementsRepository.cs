using BancoGYE_API.Models;

namespace BancoGYE_API.Repositories;

public interface IMovementsRepository
{
    (IEnumerable<Movement> Items, int TotalCount) GetPaged(
        int page, int pageSize,
        DateTime? from, DateTime? to,
        string? search);

    Movement? GetById(Guid id);
}
