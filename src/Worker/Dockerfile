# module: src.worker.dockerfile
# purpose: Container image for the Worker (Azure Container Apps). Build from repo root: docker build -f src/Worker/Dockerfile .
# exports: []
# patterns: multi_stage_build

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/ServiceDefaults/ src/ServiceDefaults/
COPY src/Domain/ src/Domain/
COPY src/Application/ src/Application/
COPY src/Infrastructure/ src/Infrastructure/
COPY src/Worker/ src/Worker/

RUN dotnet restore src/Worker/ProjectArchitecture.Worker.csproj
RUN dotnet publish src/Worker/ProjectArchitecture.Worker.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ProjectArchitecture.Worker.dll"]
