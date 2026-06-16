using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using BancoGYE_API.DTOs;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BancoGYE_API.Tests.Controller;

public class MovementsControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly JsonSerializerOptions _json = new() { PropertyNameCaseInsensitive = true };

    public MovementsControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    // Caso 1: GET /api/movements → 200 OK
    [Fact]
    public async Task GetMovements_Returns_200()
    {
        var response = await _client.GetAsync("/api/movements");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // Caso 2: Respuesta contiene metadata de paginación completa
    [Fact]
    public async Task GetMovements_Response_Has_Pagination_Metadata()
    {
        var response = await _client.GetAsync("/api/movements?page=1&pageSize=10");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.NotNull(body);
        Assert.Equal(1, body.Page);
        Assert.Equal(10, body.PageSize);
        Assert.True(body.TotalCount > 0);
        Assert.NotNull(body.Items);
    }

    // Caso 3: 1500 movimientos en seed → totalCount = 1500
    [Fact]
    public async Task GetMovements_TotalCount_Is_1500()
    {
        var response = await _client.GetAsync("/api/movements?page=1&pageSize=1");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.Equal(1500, body!.TotalCount);
    }

    // Caso 4: HasMore = true cuando hay más páginas
    [Fact]
    public async Task GetMovements_HasMore_True_When_More_Pages_Exist()
    {
        var response = await _client.GetAsync("/api/movements?page=1&pageSize=20");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.True(body!.HasMore);
    }

    // Caso 5: Última página (page=15, pageSize=100 = 1500 items) → HasMore = false
    [Fact]
    public async Task GetMovements_HasMore_False_On_Last_Page()
    {
        // pageSize is clamped to 100 — 15 pages × 100 = 1500 total
        var response = await _client.GetAsync("/api/movements?page=15&pageSize=100");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.False(body!.HasMore);
    }

    // Caso 6: Filtro por rango de fechas — retorna solo items en rango
    [Fact]
    public async Task GetMovements_DateFilter_Returns_Items_In_Range()
    {
        var from = DateTime.UtcNow.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ");
        var to = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");

        var response = await _client.GetAsync($"/api/movements?page=1&pageSize=100&from={from}&to={to}");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.NotNull(body);
        Assert.True(body.TotalCount < 1500, "Date filter must reduce results below total 1500");
    }

    // Caso 7: Búsqueda por texto — retorna items coincidentes
    [Fact]
    public async Task GetMovements_Search_Returns_Matching_Items()
    {
        var response = await _client.GetAsync("/api/movements?page=1&pageSize=100&search=Miguel");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.NotNull(body);
        Assert.True(body.TotalCount > 0);
        Assert.All(body.Items, item =>
            Assert.True(
                item.ContactName.Contains("Miguel", StringComparison.OrdinalIgnoreCase) ||
                item.Description.Contains("Miguel", StringComparison.OrdinalIgnoreCase) ||
                item.Reference.Contains("Miguel", StringComparison.OrdinalIgnoreCase)
            ));
    }

    // Caso 8: Búsqueda sin resultados → 200 con lista vacía
    [Fact]
    public async Task GetMovements_Search_NoMatch_Returns_Empty_List()
    {
        var response = await _client.GetAsync("/api/movements?search=XXXXXXXXXNOTEXIST");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(0, body!.TotalCount);
        Assert.Empty(body.Items);
    }

    // Caso 9: GET /api/movements/{id} con ID válido → 200 con detalle
    [Fact]
    public async Task GetById_Valid_Id_Returns_200_With_Detail()
    {
        var listResponse = await _client.GetAsync("/api/movements?page=1&pageSize=1");
        var list = await listResponse.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);
        var id = list!.Items.First().Id;

        var detailResponse = await _client.GetAsync($"/api/movements/{id}");
        var detail = await detailResponse.Content.ReadFromJsonAsync<MovementDetailResponse>(_json);

        Assert.Equal(HttpStatusCode.OK, detailResponse.StatusCode);
        Assert.NotNull(detail);
        Assert.Equal(id, detail.Id);
    }

    // Caso 10: GET /api/movements/{id} con ID inexistente → 404
    [Fact]
    public async Task GetById_Unknown_Id_Returns_404()
    {
        var response = await _client.GetAsync($"/api/movements/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // Caso 11: Items ordenados por fecha descendente
    [Fact]
    public async Task GetMovements_Items_Ordered_By_Date_Descending()
    {
        var response = await _client.GetAsync("/api/movements?page=1&pageSize=50");
        var body = await response.Content.ReadFromJsonAsync<PagedResponse<MovementResponse>>(_json);

        var dates = body!.Items.Select(i => i.Date).ToList();
        for (int i = 1; i < dates.Count; i++)
            Assert.True(dates[i - 1] >= dates[i], $"Date at {i - 1} must be >= date at {i}");
    }

    // Caso 12: Content-Type es application/json
    [Fact]
    public async Task GetMovements_ContentType_Is_Json()
    {
        var response = await _client.GetAsync("/api/movements");
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);
    }
}
