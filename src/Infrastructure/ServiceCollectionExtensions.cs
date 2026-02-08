/*
module: src.infrastructure
purpose: Register infrastructure services including tenant resolution and data access.
exports:
  - extension: AddInfrastructure(IServiceCollection, IConfiguration)
patterns:
  - dependency_injection
*/
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Auth;
using ProjectArchitecture.Application.Idempotency;
using ProjectArchitecture.Application.Messaging;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Infrastructure.Auth;
using ProjectArchitecture.Infrastructure.DataAccess;
using ProjectArchitecture.Infrastructure.Idempotency;
using ProjectArchitecture.Infrastructure.Messaging;
using ProjectArchitecture.Infrastructure.Tenancy;

namespace ProjectArchitecture.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        DapperConventions.Configure();

        services.Configure<PostgresOptions>(configuration.GetSection(PostgresOptions.SectionName));
        services.Configure<RedisOptions>(configuration.GetSection(RedisOptions.SectionName));
        services.Configure<TenancyOptions>(configuration.GetSection(TenancyOptions.SectionName));
        services.Configure<AbacCacheOptions>(configuration.GetSection(AbacCacheOptions.SectionName));
        services.Configure<QueueOptions>(configuration.GetSection(QueueOptions.SectionName));

        services.AddSingleton<IPostgresConnectionStringFactory, PostgresConnectionStringFactory>();
        services.AddSingleton<PostgresErrorTranslator>();
        services.AddSingleton<StoredFunctionExecutor>();
        services.AddSingleton<CatalogDbConnectionFactory>();
        services.AddSingleton<ITenantContextAccessor, TenantContextAccessor>();
        services.AddSingleton<ITenantResolutionService, TenantResolutionService>();
        services.AddSingleton<ITenantCatalogReader, TenantCatalogReader>();
        services.AddSingleton<ITenantDbConnectionFactory, TenantDbConnectionFactory>();
        services.AddSingleton<IRedisConnectionProvider, RedisConnectionProvider>();
        services.AddSingleton<IOutboxWriter, OutboxWriter>();
        services.AddSingleton<IOutboxStore, OutboxStore>();
        services.AddSingleton<IQueuePublisher, StorageQueuePublisher>();
        services.AddSingleton<IIdempotencyStore, IdempotencyStore>();
        services.AddSingleton<IRedisVersionProvider>(sp =>
        {
            var provider = sp.GetRequiredService<IRedisConnectionProvider>();
            if (provider.Multiplexer is null)
            {
                return new NullRedisVersionProvider();
            }

            return new RedisVersionProvider(provider.Multiplexer, sp.GetRequiredService<ILogger<RedisVersionProvider>>());
        });
        services.AddSingleton<ITenantCache>(sp =>
        {
            var provider = sp.GetRequiredService<IRedisConnectionProvider>();
            if (provider.Multiplexer is null)
            {
                return new NullTenantCache();
            }

            return new RedisTenantCache(provider.Multiplexer, sp.GetRequiredService<ILogger<RedisTenantCache>>());
        });
        services.AddSingleton<ISubjectAttributeCache>(sp =>
        {
            var provider = sp.GetRequiredService<IRedisConnectionProvider>();
            if (provider.Multiplexer is null)
            {
                return new NullSubjectAttributeCache();
            }

            return new RedisSubjectAttributeCache(
                provider.Multiplexer,
                sp.GetRequiredService<ILogger<RedisSubjectAttributeCache>>());
        });
        services.AddSingleton<ISubjectAttributeVersionStore>(sp =>
        {
            var provider = sp.GetRequiredService<IRedisConnectionProvider>();
            if (provider.Multiplexer is null)
            {
                return new NullSubjectAttributeVersionStore();
            }

            return new RedisSubjectAttributeVersionStore(
                provider.Multiplexer,
                sp.GetRequiredService<ILogger<RedisSubjectAttributeVersionStore>>());
        });
        services.AddSingleton<ClaimSubjectAttributeProvider>();
        services.AddSingleton<ISubjectAttributeProvider, CachedSubjectAttributeProvider>();
        services.AddSingleton<ISubjectAttributeInvalidator>(sp =>
        {
            var provider = sp.GetRequiredService<IRedisConnectionProvider>();
            if (provider.Multiplexer is null)
            {
                return new NullSubjectAttributeInvalidator();
            }

            return new SubjectAttributeInvalidator(
                sp.GetRequiredService<ISubjectAttributeVersionStore>(),
                sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<AbacCacheOptions>>(),
                sp.GetRequiredService<ILogger<SubjectAttributeInvalidator>>());
        });

        return services;
    }
}
