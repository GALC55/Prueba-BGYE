using BancoGYE_API.Data;
using BancoGYE_API.Models;

namespace BancoGYE_API.Repositories;

public class MovementsRepository : IMovementsRepository
{
    private readonly IMovementsDataStore _store;

    public MovementsRepository(IMovementsDataStore store)
    {
        _store = store;
    }

    public (IEnumerable<Movement> Items, int TotalCount) GetPaged(
        int page, int pageSize,
        DateTime? from, DateTime? to,
        string? search)
    {
        var query = _store.GetAll().AsEnumerable();

        var defaultFrom = DateTime.UtcNow.AddMonths(-3);
        from ??= defaultFrom;
        to ??= DateTime.UtcNow;

        query = query.Where(m => m.Date >= from && m.Date <= to);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            query = query.Where(m =>
                m.ContactName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                m.Description.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                m.Reference.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = query.OrderByDescending(m => m.Date);
        var total = ordered.Count();
        var items = ordered.Skip((page - 1) * pageSize).Take(pageSize);

        return (items, total);
    }

    public Movement? GetById(Guid id) =>
        _store.GetAll().FirstOrDefault(m => m.Id == id);
}
