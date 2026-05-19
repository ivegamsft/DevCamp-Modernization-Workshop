using DevCamp.Api.Data;
using DevCamp.Api.Models;
using Microsoft.AspNetCore.Mvc;

namespace DevCamp.Api.Controllers;

/// <summary>
/// Migrated from legacy <c>DevCamp.API.Controllers.IncidentController</c> (System.Web.Http).
/// Route templates and query shapes are preserved for compatibility with generated <c>IncidentAPIClient</c> in the legacy web app.
/// </summary>
[ApiController]
public class IncidentController : ControllerBase
{
    private readonly CosmosIncidentRepository _repository;

    public IncidentController(CosmosIncidentRepository repository)
    {
        _repository = repository;
    }

    [HttpGet("incidents/{IncidentId}")]
    public async Task<ActionResult<Incident>> GetById(string IncidentId, CancellationToken cancellationToken)
    {
        var incident = await _repository.GetItemAsync(IncidentId, cancellationToken);
        if (incident is null)
        {
            return NotFound();
        }

        return Ok(incident);
    }

    [HttpGet("incidents")]
    public async Task<ActionResult<IEnumerable<Incident>>> GetAllIncidents(CancellationToken cancellationToken)
    {
        var incidents = await _repository.GetItemsAsync(includeResolved: false, cancellationToken);
        return Ok(incidents);
    }

    [HttpGet("incidents/count")]
    public async Task<ActionResult<int>> GetIncidentCount(CancellationToken cancellationToken)
    {
        var count = await _repository.GetItemsCountAsync(includeResolved: false, cancellationToken);
        return Ok(count);
    }

    [HttpGet("incidents/count/includeresolved")]
    public async Task<ActionResult<int>> GetAllIncidentsCount(CancellationToken cancellationToken)
    {
        var count = await _repository.GetItemsCountAsync(includeResolved: true, cancellationToken);
        return Ok(count);
    }

    [HttpPost("incidents")]
    [HttpPost("incidents/")]
    public async Task<ActionResult<Incident>> CreateIncident([FromBody] Incident? newIncident, CancellationToken cancellationToken)
    {
        if (newIncident is null)
        {
            return BadRequest(new ApiResponseMessage { Message = "Unable to create new incident" });
        }

        var utcNow = DateTime.UtcNow;
        newIncident.Created = utcNow;
        newIncident.LastModified = utcNow;

        var created = await _repository.CreateItemAsync(newIncident, cancellationToken);
        return Ok(created);
    }

    [HttpPut("incidents")]
    [HttpPut("incidents/")]
    public async Task<ActionResult<Incident>> UpdateIncident([FromQuery] string IncidentId, [FromBody] Incident? newIncident, CancellationToken cancellationToken)
    {
        if (newIncident is null)
        {
            return BadRequest(new ApiResponseMessage { Message = "Incident is null or formatted incorrectly" });
        }

        var updated = await _repository.UpdateItemAsync(IncidentId, newIncident, cancellationToken);
        if (updated is null)
        {
            return NotFound(new ApiResponseMessage { Message = "Unable to update incident" });
        }

        return Ok(updated);
    }

    [HttpGet("incidents/clear")]
    public async Task<ActionResult<ApiResponseMessage>> ClearData(CancellationToken cancellationToken)
    {
        await _repository.ClearDatabaseAsync(cancellationToken);
        return Ok(new ApiResponseMessage { Message = "Cleared database" });
    }

    [HttpGet("incidents/sampledata")]
    public async Task<ActionResult<ApiResponseMessage>> SampleData(CancellationToken cancellationToken)
    {
        await _repository.LoadSampleDataAsync(clearData: true, cancellationToken);
        var recordCount = await _repository.GetItemsCountAsync(includeResolved: true, cancellationToken);
        return Ok(new ApiResponseMessage { Message = $"Initialized sample data with [{recordCount}] incidents" });
    }

    [HttpGet("incidents/fakedata")]
    public async Task<ActionResult<ApiResponseMessage>> FakeData(CancellationToken cancellationToken)
    {
        await _repository.LoadFakeDataAsync(clearData: true, cancellationToken);
        var recordCount = await _repository.GetItemsCountAsync(includeResolved: true, cancellationToken);
        return Ok(new ApiResponseMessage { Message = $"Initialized fake data with [{recordCount}] incidents" });
    }
}
