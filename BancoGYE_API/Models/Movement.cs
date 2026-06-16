namespace BancoGYE_API.Models;

public class Movement
{
    public Guid Id { get; set; }
    public string Reference { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ContactName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public MovementType Type { get; set; }
    public MovementStatus Status { get; set; }
    public DateTime Date { get; set; }
    public string? Notes { get; set; }
}

public enum MovementType
{
    Credit,
    Debit,
    Transfer
}

public enum MovementStatus
{
    Pending,
    Completed,
    Failed
}
