/*
module: infra.bicep.params.dev
purpose: Development environment parameter file for `main.rg.bicep`.
exports: []
patterns:
  - per_env_params: keep all non-secret env-specific values here
notes:
  - Replace placeholder names with globally-unique values before deploying.
*/

using '../main.rg.bicep'

param appName = 'saastpl'
param environmentName = 'dev'
param location = 'westus2'

// DNS root for Front Door custom domains (admin.<root>, *.<root>).
param dnsRoot = 'example.com'

// Globally-unique names required by Azure for these resources.
// appConfigName defaults in main.rg.bicep to a unique value per RG (uniqueString); override here only if needed.
param storageAccountName = 'stsaastpldev1234'
param keyVaultName = 'kv-saastpl-dev-1234'
param acrName = 'acrsaastpldev1234'

