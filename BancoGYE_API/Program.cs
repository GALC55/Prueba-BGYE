using BancoGYE_API.Data;
using BancoGYE_API.Middleware;
using BancoGYE_API.Repositories;
using BancoGYE_API.Services;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Banco Guayaquil - Movimientos API",
        Version = "v1",
        Description = "API REST para gestión de movimientos de cuenta"
    });
});

builder.Services.AddSingleton<IMovementsDataStore, MovementsDataStore>();
builder.Services.AddScoped<IMovementsRepository, MovementsRepository>();
builder.Services.AddScoped<IMovementsService, MovementsService>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

app.UseMiddleware<GlobalExceptionMiddleware>();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Banco GYE API v1");
    c.RoutePrefix = string.Empty;
});

app.UseCors();
app.MapControllers();

app.Run();

public partial class Program { }
