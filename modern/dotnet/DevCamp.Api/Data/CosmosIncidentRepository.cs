using DevCamp.Api.Models;
using DevCamp.Api.Services;
using Microsoft.Azure.Cosmos;
using Newtonsoft.Json.Linq;
using System.Net;

namespace DevCamp.Api.Data;

/// <summary>
/// Replaces legacy <c>DocumentDBRepository&lt;Incident&gt;</c> (Microsoft.Azure.DocumentDB client) with
/// <see href="https://learn.microsoft.com/azure/cosmos-db/nosql/sdk-dotnet-v3">Azure Cosmos DB .NET SDK v3</see>.
/// </summary>
public class CosmosIncidentRepository
{
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<CosmosIncidentRepository> _logger;
    private CosmosClient? _client;
    private Database? _database;
    private Container? _container;
    private string _databaseId = "";
    private string _containerId = "";

    public CosmosIncidentRepository(
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<CosmosIncidentRepository> logger)
    {
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        var endpoint = FirstNonEmpty(
            _configuration["CosmosDb:Endpoint"],
            _configuration["DOCUMENTDB_ENDPOINT"]);

        _databaseId = FirstNonEmpty(
            _configuration["CosmosDb:DatabaseId"],
            _configuration["DOCUMENTDB_DATABASEID"]) ?? "DevCamp";

        _containerId = FirstNonEmpty(
            _configuration["CosmosDb:ContainerId"],
            _configuration["DOCUMENTDB_COLLECTIONID"]) ?? "Incidents";

        if (string.IsNullOrWhiteSpace(endpoint))
        {
            throw new InvalidOperationException(
                "Cosmos DB endpoint is required (CosmosDb:Endpoint). This workshop uses Entra ID RBAC only — no account keys. " +
                "Deploy infra/ and assign Cosmos DB Built-in Data Contributor to your identity or the App Service managed identity. " +
                "See docs/steps/02-rbac-and-iac.md.");
        }

        _client = CosmosClientFactory.Create(endpoint, _logger);

        var dbResponse = await _client.CreateDatabaseIfNotExistsAsync(_databaseId, cancellationToken: cancellationToken);
        _database = dbResponse.Database;

        var containerProperties = new ContainerProperties(_containerId, partitionKeyPath: "/id")
        {
            DefaultTimeToLive = -1
        };

        var throughput = ThroughputProperties.CreateManualThroughput(400);
        var containerResponse = await _database.CreateContainerIfNotExistsAsync(
            containerProperties,
            throughput,
            cancellationToken: cancellationToken);

        _container = containerResponse.Container;
        _logger.LogInformation("Cosmos DB ready: database {Database}, container {Container}", _databaseId, _containerId);
    }

    public async Task<Incident?> GetItemAsync(string id, CancellationToken cancellationToken = default)
    {
        EnsureReady();
        try
        {
            var response = await _container!.ReadItemAsync<Incident>(
                id,
                new PartitionKey(id),
                cancellationToken: cancellationToken);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IEnumerable<Incident>> GetItemsAsync(bool includeResolved, CancellationToken cancellationToken = default)
    {
        EnsureReady();
        var sql = includeResolved
            ? "SELECT * FROM c"
            : "SELECT * FROM c WHERE c.Resolved = false";

        var query = new QueryDefinition(sql);
        using var iterator = _container!.GetItemQueryIterator<Incident>(query);
        var results = new List<Incident>();
        while (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(cancellationToken);
            results.AddRange(page);
        }

        return results.OrderBy(i => i.SortKey);
    }

    public async Task<int> GetItemsCountAsync(bool includeResolved, CancellationToken cancellationToken = default)
    {
        EnsureReady();
        var sql = includeResolved
            ? "SELECT VALUE COUNT(1) FROM c"
            : "SELECT VALUE COUNT(1) FROM c WHERE c.Resolved = false";

        var query = new QueryDefinition(sql);
        using var iterator = _container!.GetItemQueryIterator<int>(query);
        if (!iterator.HasMoreResults)
        {
            return 0;
        }

        var page = await iterator.ReadNextAsync(cancellationToken);
        return page.Resource.FirstOrDefault();
    }

    public async Task<Incident> CreateItemAsync(Incident item, CancellationToken cancellationToken = default)
    {
        EnsureReady();
        item.Id ??= Guid.NewGuid().ToString();
        var response = await _container!.CreateItemAsync(
            item,
            new PartitionKey(item.Id),
            cancellationToken: cancellationToken);
        return response.Resource;
    }

    public async Task<Incident?> UpdateItemAsync(string id, Incident item, CancellationToken cancellationToken = default)
    {
        EnsureReady();
        item.Id = id;
        try
        {
            var response = await _container!.ReplaceItemAsync(
                item,
                id,
                new PartitionKey(id),
                cancellationToken: cancellationToken);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task ClearDatabaseAsync(CancellationToken cancellationToken = default)
    {
        EnsureReady();
        try
        {
            await _database!.DeleteAsync(cancellationToken: cancellationToken);
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            _logger.LogWarning(ex, "Database {Database} not found during clear; recreating.", _databaseId);
        }

        var dbResponse = await _client!.CreateDatabaseIfNotExistsAsync(_databaseId, cancellationToken: cancellationToken);
        _database = dbResponse.Database;

        var containerResponse = await _database.CreateContainerIfNotExistsAsync(
            new ContainerProperties(_containerId, "/id"),
            ThroughputProperties.CreateManualThroughput(400),
            cancellationToken: cancellationToken);

        _container = containerResponse.Container;
    }

    public async Task LoadSampleDataAsync(bool clearData, CancellationToken cancellationToken = default)
    {
        if (clearData)
        {
            await ClearDatabaseAsync(cancellationToken);
        }

        foreach (var incident in ReadSampleIncidents())
        {
            await _container!.CreateItemAsync(
                incident,
                new PartitionKey(incident.Id),
                cancellationToken: cancellationToken);
        }
    }

    public async Task LoadFakeDataAsync(bool clearData, CancellationToken cancellationToken = default)
    {
        if (clearData)
        {
            await ClearDatabaseAsync(cancellationToken);
        }

        foreach (var incident in ReadFakeIncidents())
        {
            await _container!.CreateItemAsync(
                incident,
                new PartitionKey(incident.Id),
                cancellationToken: cancellationToken);
        }
    }

    private List<Incident> ReadSampleIncidents()
    {
        var path = Path.Combine(_environment.ContentRootPath, "Data", "SampleIncidents.json");
        try
        {
            var sampleData = JObject.Parse(File.ReadAllText(path));
            var samples = sampleData["sampleincidents"]?.ToObject<List<Incident>>() ?? new List<Incident>();
            foreach (var s in samples)
            {
                s.SortKey = string.Format("{0:D19}", DateTime.MaxValue.Ticks - (s.Created ?? DateTime.UtcNow).Ticks);
            }

            return samples;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not load {Path}; generating in-memory sample incidents.", path);
            return GenerateFallbackSamples();
        }
    }

    private List<Incident> ReadFakeIncidents()
    {
        var path = Path.Combine(_environment.ContentRootPath, "Data", "FakeIncidents.json");
        try
        {
            var data = JObject.Parse(File.ReadAllText(path));
            var list = data["fakeincidents"]?.ToObject<List<Incident>>() ?? new List<Incident>();
            foreach (var s in list)
            {
                s.Id ??= Guid.NewGuid().ToString();
                s.SortKey = string.Format("{0:D19}", DateTime.MaxValue.Ticks - (s.Created ?? DateTime.UtcNow).Ticks);
            }

            return list;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not load {Path}; falling back to sample incidents.", path);
            return ReadSampleIncidents();
        }
    }

    private static List<Incident> GenerateFallbackSamples()
    {
        const int max = 10;
        var samples = new List<Incident>();
        for (var i = 0; i < max; i++)
        {
            var utcNow = DateTime.UtcNow;
            samples.Add(new Incident
            {
                FirstName = "first-" + i,
                LastName = "last-" + i,
                OutageType = "Outage-" + i,
                City = "city-" + i,
                Description = "description-" + i,
                IsEmergency = false,
                Resolved = false,
                State = "IL",
                Street = "street-" + i,
                ZipCode = "50500-" + i,
                PhoneNumber = "555555000-" + i,
                Created = utcNow,
                LastModified = utcNow,
                Tags = "Street, Cars"
            });
        }

        return samples;
    }

    private void EnsureReady()
    {
        if (_container is null)
        {
            throw new InvalidOperationException("Cosmos DB is not initialized. Call InitializeAsync at startup.");
        }
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        foreach (var v in values)
        {
            if (!string.IsNullOrWhiteSpace(v))
            {
                return v;
            }
        }

        return null;
    }
}
