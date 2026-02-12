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
param location = 'eastus'

param dnsRoot = 'example.com'

param storageAccountName = 'stsaastplstg1234'
param keyVaultName = 'kv-saastpl-stg-1234'
param acrName = 'acrsaastplstg1234'
param appConfigName = 'appcs-saastpl-stg-1234'

