using BancoGYE_API.Data;

namespace BancoGYE_API.Tests.DataStore;

public class MovementsDataStoreTests
{
    private readonly IMovementsDataStore _store = new MovementsDataStore();

    // Caso 1: Seed genera exactamente 1500 movimientos
    [Fact]
    public void GetAll_Returns_1500_Movements()
    {
        var all = _store.GetAll();
        Assert.Equal(1500, all.Count);
    }

    // Caso 2: Todos los movimientos tienen ID único
    [Fact]
    public void GetAll_All_Movements_Have_Unique_Ids()
    {
        var ids = _store.GetAll().Select(m => m.Id).ToHashSet();
        Assert.Equal(1500, ids.Count);
    }

    // Caso 3: Todos los movimientos están dentro de los últimos 3 meses
    [Fact]
    public void GetAll_All_Movements_Within_3_Months()
    {
        var limit = DateTime.UtcNow.AddMonths(-3);
        var all = _store.GetAll();
        Assert.All(all, m => Assert.True(m.Date >= limit,
            $"Movement {m.Id} date {m.Date} is older than 3 months"));
    }

    // Caso 4: Movimientos ordenados por fecha descendente
    [Fact]
    public void GetAll_Returns_Movements_Ordered_By_Date_Descending()
    {
        var dates = _store.GetAll().Select(m => m.Date).ToList();
        for (int i = 1; i < dates.Count; i++)
            Assert.True(dates[i - 1] >= dates[i],
                $"Date at index {i - 1} should be >= date at index {i}");
    }

    // Caso 5: Todos los movimientos tienen referencia no vacía
    [Fact]
    public void GetAll_All_Movements_Have_Non_Empty_Reference()
    {
        Assert.All(_store.GetAll(), m => Assert.False(string.IsNullOrWhiteSpace(m.Reference)));
    }

    // Caso 6: Todos los movimientos tienen contactName no vacío
    [Fact]
    public void GetAll_All_Movements_Have_ContactName()
    {
        Assert.All(_store.GetAll(), m => Assert.False(string.IsNullOrWhiteSpace(m.ContactName)));
    }

    // Caso 7: Amounts son positivos
    [Fact]
    public void GetAll_All_Amounts_Are_Positive()
    {
        Assert.All(_store.GetAll(), m => Assert.True(m.Amount > 0));
    }
}
