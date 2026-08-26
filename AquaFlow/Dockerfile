FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5161
ENV ASPNETCORE_URLS=http://+:5161
ENV ASPNETCORE_ENVIRONMENT=Development


FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .

FROM build AS publish
RUN dotnet publish "AquaFlow.WebAPI/AquaFlow.WebAPI.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .

ENTRYPOINT ["dotnet", "AquaFlow.WebAPI.dll"]
