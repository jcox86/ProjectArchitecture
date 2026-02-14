/*
module: infra.bicep.params.prod
purpose: Production environment parameter file for `main.rg.bicep`.
exports: []
patterns:
  - per_env_params: keep all non-secret env-specific values here
notes:
  - Defaults Front Door tier to Premium via `main.rg.bicep` defaulting logic.
  - Replace placeholder names with globally-unique values before deploying.
*/

using '../main.rg.bicep'

param appName = 'saastpl'
param environmentName = 'prod'
param location = 'westus2'

param dnsRoot = 'example.com'

// appConfigName defaults in main.rg.bicep to a unique value per RG; override here only if needed.
param storageAccountName = 'stsaastplprod1234'
param keyVaultName = 'kv-saastpl-prod-1234'
param acrName = 'acrsaastplprod1234'

