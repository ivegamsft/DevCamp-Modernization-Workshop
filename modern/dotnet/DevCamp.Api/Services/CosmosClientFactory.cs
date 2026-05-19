using Azure.Identity;
using Microsoft.Azure.Cosmos;

namespace DevCamp.Api.Services;

/// <summary>
/// Creates <see cref="CosmosClient"/> instances using Entra ID (RBAC) — no account keys.
/// </summary>
public static class CosmosClientFactory
{
    public static CosmosClient Create(string accountEndpoint, ILogger? logger = null)
    {
        if (string.IsNullOrWhiteSpace(accountEndpoint))
        {
            throw new ArgumentException("Cosmos DB account endpoint is required.", nameof(accountEndpoint));
        }

        logger?.LogInformation("Creating CosmosClient with DefaultAzureCredential (managed identity / Azure CLI).");

        return new CosmosClient(
            accountEndpoint,
            new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ExcludeInteractiveBrowserCredential = false
            }),
            new CosmosClientOptions
            {
                ApplicationName = "DevCamp.Modern.Api"
            });
    }
}
