using BancoGYE_API.Models;

namespace BancoGYE_API.Data;

public interface IMovementsDataStore
{
    IReadOnlyList<Movement> GetAll();
}

public class MovementsDataStore : IMovementsDataStore
{
    private readonly List<Movement> _movements;

    public MovementsDataStore()
    {
        _movements = GenerateMovements(1500);
    }

    public IReadOnlyList<Movement> GetAll() => _movements.AsReadOnly();

    private static List<Movement> GenerateMovements(int count)
    {
        var rng = new Random(42);
        var contacts = new[]
        {
            "Miguel Hernández", "Ana García", "Luis Pérez", "María López",
            "Carlos Rodríguez", "Sofía Martínez", "Juan Torres", "Laura Sánchez",
            "Diego Ramírez", "Valeria Castro", "Empresa ABC S.A.", "Distribuidora XYZ",
            "Servicios Tech Cía.", "Importadora Norte", "Constructora Sur"
        };

        var descriptions = new[]
        {
            "Transferencia bancaria", "Pago de servicios", "Cobro de factura",
            "Depósito en cuenta", "Pago proveedor", "Reembolso", "Cobro mensual",
            "Pago nómina", "Compra online", "Pago arriendo"
        };

        var statuses = new[] { MovementStatus.Completed, MovementStatus.Pending, MovementStatus.Failed };
        var types = new[] { MovementType.Credit, MovementType.Debit, MovementType.Transfer };

        var now = DateTime.UtcNow;
        var movements = new List<Movement>(count);

        for (int i = 0; i < count; i++)
        {
            var daysBack = rng.NextDouble() * 90;
            var date = now.AddDays(-daysBack);
            var type = types[rng.Next(types.Length)];
            var status = statuses[rng.Next(statuses.Length)];
            var contact = contacts[rng.Next(contacts.Length)];
            var description = descriptions[rng.Next(descriptions.Length)];
            var amount = Math.Round((decimal)(rng.NextDouble() * 4950 + 50), 2);

            movements.Add(new Movement
            {
                Id = Guid.NewGuid(),
                Reference = $"REF-{100000 + i:D6}",
                Description = description,
                ContactName = contact,
                Amount = amount,
                Type = type,
                Status = status,
                Date = date,
                Notes = rng.Next(5) == 0 ? $"Nota {i}" : null
            });
        }

        return movements.OrderByDescending(m => m.Date).ToList();
    }
}
