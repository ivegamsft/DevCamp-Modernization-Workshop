using Newtonsoft.Json;

namespace DevCamp.Api.Models;

/// <summary>
/// Migrated from legacy <c>DevCamp.API.Models.Incident</c> (ASP.NET Web API on .NET Framework 4.5).
/// <see cref="Id"/> uses JSON name <c>id</c> to match existing Cosmos DB / DocumentDB documents and clients.
/// </summary>
public class Incident
{
    [JsonProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    public string? Description { get; set; }
    public string? Street { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? ZipCode { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? OutageType { get; set; }
    public bool IsEmergency { get; set; }
    public bool Resolved { get; set; }
    public Uri? ImageUri { get; set; }
    public Uri? ThumbnailUri { get; set; }
    public DateTime? Created { get; set; }
    public DateTime? LastModified { get; set; }
    public string? SortKey { get; set; }
    public string? Tags { get; set; }

    public Incident()
    {
        SortKey = string.Format("{0:D19}", DateTime.MaxValue.Ticks - DateTime.UtcNow.Ticks);
    }
}
