# module: src.api.dockerfile
# purpose: Container image for the API (Azure Container Apps). Build from repo root: docker build -f src/Api/Dockerfile .
# exports: []
# patterns: multi_stage_build

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/ServiceDefaults/ src/ServiceDefaults/
COPY src/Domain/ src/Domain/
COPY src/Application/ src/Application/
COPY src/Infrastructure/ src/Infrastructure/
COPY src/Api/ src/Api/

RUN dotnet restore src/Api/ProjectArchitecture.Api.csproj
RUN dotnet publish src/Api/ProjectArchitecture.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "ProjectArchitecture.Api.dll"]
