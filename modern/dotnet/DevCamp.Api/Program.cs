using DevCamp.Api.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers().AddNewtonsoftJson();
builder.Services.AddSingleton<CosmosIncidentRepository>();

var app = builder.Build();

await app.Services.GetRequiredService<CosmosIncidentRepository>().InitializeAsync();

app.UseHttpsRedirection();
app.MapControllers();

app.MapGet("/", () => Results.Text(
    "DevCamp.Api (.NET 8) — incident routes match legacy Web API. See repo README and docs/MIGRATION-JOURNAL.md.",
    "text/plain"));

app.Run();
