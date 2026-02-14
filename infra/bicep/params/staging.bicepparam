/*
module: infra.bicep.params.staging
purpose: Staging environment parameter file for `main.rg.bicep`.
exports: []
patterns:
  - per_env_params: keep all non-secret env-specific values here
notes:
  - Replace placeholder names with globally-unique values before deploying.
*/

using '../main.rg.bicep'

param appName = 'saastpl'
param environmentName = 'staging'
param location = 'westus2'

param dnsRoot = 'example.com'

// appConfigName defaults in main.rg.bicep to a unique value per RG; override here only if needed.
param storageAccountName = 'stsaastplstg1234'
param keyVaultName = 'kv-saastpl-stg-1234'
param acrName = 'acrsaastplstg1234'

