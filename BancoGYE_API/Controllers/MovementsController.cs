using BancoGYE_API.DTOs;
using BancoGYE_API.Services;
using Microsoft.AspNetCore.Mvc;

namespace BancoGYE_API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class MovementsController : ControllerBase
{
    private readonly IMovementsService _service;

    public MovementsController(IMovementsService service)
    {
        _service = service;
    }

    /// <summary>
    /// Obtiene movimientos paginados con filtros opcionales.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResponse<MovementResponse>), 200)]
    public IActionResult GetMovements(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] DateTime? from = null,
        [FromQuery] DateTime? to = null,
        [FromQuery] string? search = null)
    {
        var query = new MovementsQueryRequest(page, pageSize, from, to, search);
        var result = _service.GetMovements(query);
        return Ok(result);
    }

    /// <summary>
    /// Obtiene el detalle de un movimiento específico.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(MovementDetailResponse), 200)]
    [ProducesResponseType(404)]
    public IActionResult GetById(Guid id)
    {
        var result = _service.GetMovementById(id);
        if (result is null) return NotFound(new { message = "Movimiento no encontrado." });
        return Ok(result);
    }
}
