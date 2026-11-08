FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5161
ENV ASPNETCORE_URLS=http://+:5161
ENV ASPNETCORE_ENVIRONMENT=Development

# ML.NET TimeSeries (SSA forecast/spike detection) uses Intel MKL (libMklImports.so),
# which needs the OpenMP runtime libiomp5.so. The NuGet package does not ship it for
# Linux; Debian's libomp-dev (LLVM OpenMP, ABI-compatible) provides libiomp5.so.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libomp-dev \
    && rm -rf /var/lib/apt/lists/* \
    && test -e /usr/lib/x86_64-linux-gnu/libiomp5.so


FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .

FROM build AS publish
RUN dotnet publish "AquaFlow.WebAPI/AquaFlow.WebAPI.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .

ENTRYPOINT ["dotnet", "AquaFlow.WebAPI.dll"]
