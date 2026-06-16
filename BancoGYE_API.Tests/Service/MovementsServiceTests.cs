using BancoGYE_API.DTOs;
using BancoGYE_API.Models;
using BancoGYE_API.Repositories;
using BancoGYE_API.Services;

namespace BancoGYE_API.Tests.Service;

// MARK: - Mock Repository

internal class MockMovementsRepository : IMovementsRepository
{
    public List<Movement> Movements { get; set; } = [];

    public (IEnumerable<Movement> Items, int TotalCount) GetPaged(
        int page, int pageSize, DateTime? from, DateTime? to, string? search)
    {
        var query = Movements.AsEnumerable();
        if (from.HasValue) query = query.Where(m => m.Date >= from);
        if (to.HasValue) query = query.Where(m => m.Date <= to);
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(m => m.ContactName.Contains(search, StringComparison.OrdinalIgnoreCase));

        var ordered = query.OrderByDescending(m => m.Date);
        var total = ordered.Count();
        return (ordered.Skip((page - 1) * pageSize).Take(pageSize), total);
    }

    public Movement? GetById(Guid id) => Movements.FirstOrDefault(m => m.Id == id);
}

internal static class MovementFactory
{
    public static Movement Create(int daysAgo = 0, string contact = "Test User") => new()
    {
        Id = Guid.NewGuid(),
        Reference = $"REF-{Guid.NewGuid():N}",
        Description = "Descripción test",
        ContactName = contact,
        Amount = 100m,
        Type = MovementType.Credit,
        Status = MovementStatus.Completed,
        Date = DateTime.UtcNow.AddDays(-daysAgo)
    };
}

// MARK: - Tests

public class MovementsServiceTests
{
    private readonly MockMovementsRepository _repo;
    private readonly IMovementsService _service;

    public MovementsServiceTests()
    {
        _repo = new MockMovementsRepository();
        _service = new MovementsService(_repo);
    }

    // Caso 1: Respuesta incluye metadata de paginación completa
    [Fact]
    public void GetMovements_Response_Includes_Pagination_Metadata()
    {
        _repo.Movements = Enumerable.Range(0, 50).Select(i => MovementFactory.Create(i)).ToList();
        var query = new MovementsQueryRequest(Page: 1, PageSize: 20);

        var result = _service.GetMovements(query);

        Assert.Equal(1, result.Page);
        Assert.Equal(20, result.PageSize);
        Assert.Equal(50, result.TotalCount);
        Assert.True(result.HasMore);
    }

    // Caso 2: HasMore = false en última página
    [Fact]
    public void GetMovements_HasMore_False_On_Last_Page()
    {
        _repo.Movements = Enumerable.Range(0, 10).Select(i => MovementFactory.Create(i)).ToList();
        var query = new MovementsQueryRequest(Page: 1, PageSize: 20);

        var result = _service.GetMovements(query);

        Assert.False(result.HasMore);
        Assert.Equal(10, result.TotalCount);
    }

    // Caso 3: pageSize se limita a máximo 100
    [Fact]
    public void GetMovements_PageSize_Clamped_To_100()
    {
        _repo.Movements = Enumerable.Range(0, 200).Select(i => MovementFactory.Create(i)).ToList();
        var query = new MovementsQueryRequest(Page: 1, PageSize: 999);

        var result = _service.GetMovements(query);

        Assert.Equal(100, result.PageSize);
        Assert.Equal(100, result.Items.Count());
    }

    // Caso 4: pageSize mínimo es 1
    [Fact]
    public void GetMovements_PageSize_Minimum_Is_1()
    {
        _repo.Movements = [MovementFactory.Create()];
        var query = new MovementsQueryRequest(Page: 1, PageSize: 0);

        var result = _service.GetMovements(query);

        Assert.Equal(1, result.PageSize);
    }

    // Caso 5: page mínimo es 1 aunque se pase 0 o negativo
    [Fact]
    public void GetMovements_Page_Minimum_Is_1()
    {
        _repo.Movements = [MovementFactory.Create()];
        var query = new MovementsQueryRequest(Page: -5, PageSize: 20);

        var result = _service.GetMovements(query);

        Assert.Equal(1, result.Page);
    }

    // Caso 6: Items mapeados correctamente a DTO (no expone entidad interna)
    [Fact]
    public void GetMovements_Items_Mapped_To_Response_DTO()
    {
        var movement = MovementFactory.Create(contact: "Ana García");
        _repo.Movements = [movement];
        var query = new MovementsQueryRequest(Page: 1, PageSize: 20);

        var result = _service.GetMovements(query);
        var item = result.Items.Single();

        Assert.Equal(movement.Id, item.Id);
        Assert.Equal("Ana García", item.ContactName);
        Assert.Equal("Credit", item.Type);
        Assert.Equal("Completed", item.Status);
    }

    // Caso 7: GetMovementById retorna detalle completo
    [Fact]
    public void GetMovementById_Returns_Full_Detail()
    {
        var movement = MovementFactory.Create();
        movement.Notes = "Nota importante";
        _repo.Movements = [movement];

        var result = _service.GetMovementById(movement.Id);

        Assert.NotNull(result);
        Assert.Equal(movement.Id, result.Id);
        Assert.Equal(movement.Reference, result.Reference);
        Assert.Equal("Nota importante", result.Notes);
    }

    // Caso 8: GetMovementById con ID inexistente retorna null
    [Fact]
    public void GetMovementById_Unknown_Id_Returns_Null()
    {
        _repo.Movements = [MovementFactory.Create()];

        var result = _service.GetMovementById(Guid.NewGuid());

        Assert.Null(result);
    }

    // Caso 9: Lista vacía → items vacíos, total 0, hasMore false
    [Fact]
    public void GetMovements_Empty_Store_Returns_Empty_Response()
    {
        _repo.Movements = [];
        var query = new MovementsQueryRequest(Page: 1, PageSize: 20);

        var result = _service.GetMovements(query);

        Assert.Empty(result.Items);
        Assert.Equal(0, result.TotalCount);
        Assert.False(result.HasMore);
    }

    // Caso 10: Búsqueda por texto se pasa al repositorio
    [Fact]
    public void GetMovements_Search_Filters_By_ContactName()
    {
        _repo.Movements =
        [
            MovementFactory.Create(contact: "Miguel Hernández"),
            MovementFactory.Create(contact: "Ana García"),
            MovementFactory.Create(contact: "Miguel Torres"),
        ];
        var query = new MovementsQueryRequest(Page: 1, PageSize: 20, Search: "Miguel");

        var result = _service.GetMovements(query);

        Assert.Equal(2, result.TotalCount);
        Assert.All(result.Items, item => Assert.Contains("Miguel", item.ContactName));
    }
}
