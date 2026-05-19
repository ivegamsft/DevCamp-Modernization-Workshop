# Modern .NET (`modern/dotnet`)

## Solution

Open or build:

```powershell
dotnet build DevCamp.Modern.slnx
```

> **Note:** Recent .NET SDK versions may default to **XML-based solution files** (`.slnx`). Visual Studio 2022 17.10+ and the CLI support this format. If you need a classic `.sln`, run `dotnet new sln` in a clean folder and `dotnet sln add DevCamp.Api/DevCamp.Api.csproj`.

## Projects

| Project | Description |
|---------|-------------|
| `DevCamp.Api` | ASP.NET Core 8 incident API (Cosmos DB backend). |

## Configuration

See `DevCamp.Api/appsettings.json` and [Step 01 documentation](../../docs/steps/01-migrate-incident-api.md).
