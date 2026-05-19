using Newtonsoft.Json;

namespace DevCamp.Api.Models;

/// <summary>
/// JSON shape aligned with the legacy <c>ApiResponseMsg</c> public fields used by workshop clients.
/// </summary>
public class ApiResponseMessage
{
    [JsonProperty(Order = 1)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonProperty(Order = 2)]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [JsonProperty(Order = 3)]
    public string Message { get; set; } = "";
}
