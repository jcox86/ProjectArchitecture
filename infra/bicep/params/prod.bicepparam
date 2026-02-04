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
param environment = 'prod'
param location = 'eastus'

param dnsRoot = 'example.com'

param storageAccountName = 'stsaastplprod1234'
param keyVaultName = 'kv-saastpl-prod-1234'
param acrName = 'acrsaastplprod1234'
param appConfigName = 'appcs-saastpl-prod-1234'

