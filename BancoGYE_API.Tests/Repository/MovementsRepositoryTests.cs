using BancoGYE_API.Data;
using BancoGYE_API.Models;
using BancoGYE_API.Repositories;

namespace BancoGYE_API.Tests.Repository;

public class MovementsRepositoryTests
{
    private readonly IMovementsRepository _repo;

    public MovementsRepositoryTests()
    {
        _repo = new MovementsRepository(new MovementsDataStore());
    }

    // Caso 1: Paginación - primera página retorna pageSize items
    [Fact]
    public void GetPaged_FirstPage_Returns_Correct_Count()
    {
        var (items, _) = _repo.GetPaged(1, 20, null, null, null);
        Assert.Equal(20, items.Count());
    }

    // Caso 2: Paginación - segunda página retorna items diferentes
    [Fact]
    public void GetPaged_SecondPage_Returns_Different_Items()
    {
        var (page1, _) = _repo.GetPaged(1, 20, null, null, null);
        var (page2, _) = _repo.GetPaged(2, 20, null, null, null);

        var ids1 = page1.Select(m => m.Id).ToHashSet();
        var ids2 = page2.Select(m => m.Id).ToHashSet();
        Assert.Empty(ids1.Intersect(ids2));
    }

    // Caso 3: TotalCount refleja total real sin paginación
    [Fact]
    public void GetPaged_TotalCount_Reflects_Full_Dataset()
    {
        var (_, total) = _repo.GetPaged(1, 20, null, null, null);
        Assert.Equal(1500, total);
    }

    // Caso 4: Filtro por rango de fechas - excluye fuera de rango
    [Fact]
    public void GetPaged_DateFilter_Excludes_OutOfRange_Movements()
    {
        var from = DateTime.UtcNow.AddDays(-7);
        var to = DateTime.UtcNow;
        var (items, _) = _repo.GetPaged(1, 100, from, to, null);

        Assert.All(items, m =>
        {
            Assert.True(m.Date >= from);
            Assert.True(m.Date <= to);
        });
    }

    // Caso 5: Filtro hasta 3 meses - no retorna movimientos más antiguos
    [Fact]
    public void GetPaged_Max3Months_Enforced_By_Default()
    {
        var threeMonthsAgo = DateTime.UtcNow.AddMonths(-3);
        var (items, _) = _repo.GetPaged(1, 1500, null, null, null);
        Assert.All(items, m => Assert.True(m.Date >= threeMonthsAgo.AddDays(-1)));
    }

    // Caso 6: Búsqueda por nombre de contacto
    [Fact]
    public void GetPaged_Search_By_ContactName_Returns_Matching_Results()
    {
        var (items, total) = _repo.GetPaged(1, 100, null, null, "Miguel");
        Assert.True(total > 0);
        Assert.All(items, m =>
            Assert.True(
                m.ContactName.Contains("Miguel", StringComparison.OrdinalIgnoreCase) ||
                m.Description.Contains("Miguel", StringComparison.OrdinalIgnoreCase) ||
                m.Reference.Contains("Miguel", StringComparison.OrdinalIgnoreCase)
            ));
    }

    // Caso 7: Búsqueda por referencia
    [Fact]
    public void GetPaged_Search_By_Reference_Returns_Matching_Results()
    {
        var (items, total) = _repo.GetPaged(1, 10, null, null, "REF-100001");
        Assert.True(total >= 1);
        Assert.Contains(items, m => m.Reference.Contains("REF-100001"));
    }

    // Caso 8: Búsqueda sin resultados → total 0
    [Fact]
    public void GetPaged_Search_NoMatch_Returns_Empty()
    {
        var (items, total) = _repo.GetPaged(1, 20, null, null, "XXXXXXXXXNOTEXIST");
        Assert.Equal(0, total);
        Assert.Empty(items);
    }

    // Caso 9: Resultados ordenados por fecha descendente
    [Fact]
    public void GetPaged_Results_Ordered_By_Date_Descending()
    {
        var (items, _) = _repo.GetPaged(1, 50, null, null, null);
        var dates = items.Select(m => m.Date).ToList();
        for (int i = 1; i < dates.Count; i++)
            Assert.True(dates[i - 1] >= dates[i]);
    }

    // Caso 10: pageSize máximo respetado - no retorna más de lo pedido
    [Fact]
    public void GetPaged_Respects_PageSize()
    {
        var (items, _) = _repo.GetPaged(1, 5, null, null, null);
        Assert.Equal(5, items.Count());
    }

    // Caso 11: GetById retorna movimiento correcto
    [Fact]
    public void GetById_Returns_Correct_Movement()
    {
        var store = new MovementsDataStore();
        var repo = new MovementsRepository(store);
        var expected = store.GetAll().First();

        var result = repo.GetById(expected.Id);

        Assert.NotNull(result);
        Assert.Equal(expected.Id, result.Id);
        Assert.Equal(expected.ContactName, result.ContactName);
    }

    // Caso 12: GetById con ID inexistente retorna null
    [Fact]
    public void GetById_Unknown_Id_Returns_Null()
    {
        var result = _repo.GetById(Guid.NewGuid());
        Assert.Null(result);
    }
}
