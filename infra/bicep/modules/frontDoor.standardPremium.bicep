/*
module: infra.bicep.modules.frontDoor
purpose: Provision Azure Front Door (Standard/Premium parameterized) with WAF, origins (API/AdminUi), and routes; optionally bind custom domains and customer-managed wildcard certificate from Key Vault.
exports:
  - outputs.frontDoorEndpointHostName
  - outputs.profileId
  - outputs.endpointId
  - outputs.adminCustomDomainValidation
  - outputs.tenantWildcardDomainValidation
patterns:
  - edge_waf_then_origin: Front Door is the internet edge; origins are Container Apps ingress FQDNs
  - blue_green_ready: designed to work with ACA revisions + health probes
notes:
  - Custom domains are optional because DNS + cert provisioning varies by org.
  - Wildcard certificate baseline is customer-managed in Key Vault.
*/

targetScope = 'resourceGroup'

param appName string
param environment string

@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string

@description('Globally unique AFD endpoint name. Determines the default hostname: <endpoint>.azurefd.net')
param endpointName string

@description('Origin host name for API (Container Apps ingress FQDN).')
param originHostNameApi string

@description('Origin host name for Admin UI (Container Apps ingress FQDN).')
param originHostNameAdminUi string

@description('Enable custom domains (admin.<root> and *.<root>) with customer-managed certificate from Key Vault.')
param enableCustomDomains bool = false

@description('DNS root domain (e.g., "app.com").')
param dnsRoot string = ''

@description('Key Vault name containing the wildcard certificate secret (required when enableCustomDomains).')
param certificateKeyVaultName string = ''

@description('Key Vault secret name containing the wildcard certificate (required when enableCustomDomains).')
param certificateKeyVaultSecretName string = ''

@description('Key Vault secret version for the wildcard certificate. Empty uses latest.')
param certificateKeyVaultSecretVersion string = ''

@allowed([
  'Detection'
  'Prevention'
])
param wafMode string = 'Prevention'

@description('Managed WAF rule sets (Premium only).')
param wafManagedRuleSets array = [
  {
    ruleSetType: 'Microsoft_DefaultRuleSet'
    ruleSetVersion: '1.1'
  }
  {
    ruleSetType: 'Microsoft_BotManagerRuleSet'
    ruleSetVersion: '1.0'
  }
]

var profileName = 'afd-${appName}-${environment}'
var originGroupApiName = 'og-api'
var originGroupAdminName = 'og-adminui'
var originApiName = 'origin-api'
var originAdminName = 'origin-adminui'

var adminHostName = (empty(dnsRoot) ? '' : 'admin.${dnsRoot}')
var tenantWildcardHostName = (empty(dnsRoot) ? '' : '*.${dnsRoot}')

// Create a valid resource name: strip dots and wildcard characters.
var adminDomainResourceName = replace(adminHostName, '.', '-')
var tenantWildcardDomainResourceName = replace(replace(tenantWildcardHostName, '.', '-'), '*', 'wildcard')

resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: profileName
  location: 'global'
  sku: {
    name: skuName
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: endpointName
  parent: profile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroupApi 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: originGroupApiName
  parent: profile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource originGroupAdmin 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: originGroupAdminName
  parent: profile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource originApi 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: originApiName
  parent: originGroupApi
  properties: {
    hostName: originHostNameApi
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHostNameApi
    priority: 1
    weight: 1000
  }
}

resource originAdmin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: originAdminName
  parent: originGroupAdmin
  properties: {
    hostName: originHostNameAdminUi
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHostNameAdminUi
    priority: 1
    weight: 1000
  }
}

// Optional custom domain + customer cert secret (wildcard cert covers admin.<root> as well).
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (enableCustomDomains) {
  name: certificateKeyVaultName

  resource secret 'secrets' existing = {
    name: certificateKeyVaultSecretName
  }
}

resource customerCertSecret 'Microsoft.Cdn/profiles/secrets@2021-06-01' = if (enableCustomDomains) {
  name: 'cert-${appName}-${environment}'
  parent: profile
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      useLatestVersion: (certificateKeyVaultSecretVersion == '')
      secretVersion: certificateKeyVaultSecretVersion
      secretSource: {
        id: keyVault::secret.id
      }
    }
  }
}

resource adminCustomDomain 'Microsoft.Cdn/profiles/customDomains@2021-06-01' = if (enableCustomDomains) {
  name: adminDomainResourceName
  parent: profile
  properties: {
    hostName: adminHostName
    tlsSettings: {
      certificateType: 'CustomerCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
        id: customerCertSecret.id
      }
    }
  }
}

resource tenantWildcardCustomDomain 'Microsoft.Cdn/profiles/customDomains@2021-06-01' = if (enableCustomDomains) {
  name: tenantWildcardDomainResourceName
  parent: profile
  properties: {
    hostName: tenantWildcardHostName
    tlsSettings: {
      certificateType: 'CustomerCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
        id: customerCertSecret.id
      }
    }
  }
}

// Routes for admin.<root> and default domain
resource routeAdminApi 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'route-admin-api'
  parent: endpoint
  dependsOn: [
    originApi // ensure origin group isn't empty
  ]
  properties: {
    originGroup: {
      id: originGroupApi.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/api/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    customDomains: enableCustomDomains ? [
      {
        id: adminCustomDomain.id
      }
    ] : []
  }
}

resource routeAdminUi 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'route-admin-ui'
  parent: endpoint
  dependsOn: [
    originAdmin // ensure origin group isn't empty
  ]
  properties: {
    originGroup: {
      id: originGroupAdmin.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    customDomains: enableCustomDomains ? [
      {
        id: adminCustomDomain.id
      }
    ] : []
  }
}

// Route for tenant wildcard domain only (avoid default-domain ambiguity by not linking to default domain).
resource routeTenantApi 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = if (enableCustomDomains) {
  name: 'route-tenant-api'
  parent: endpoint
  dependsOn: [
    originApi
  ]
  properties: {
    originGroup: {
      id: originGroupApi.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Disabled'
    customDomains: [
      {
        id: tenantWildcardCustomDomain.id
      }
    ]
  }
}

// WAF (parameterized: managed rules require Premium)
resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: 'waf-${appName}-${environment}'
  location: 'global'
  sku: {
    name: skuName
  }
  properties: union({
    policySettings: {
      enabledState: 'Enabled'
      mode: wafMode
    }
  }, skuName == 'Premium_AzureFrontDoor' ? {
    managedRules: {
      managedRuleSets: wafManagedRuleSets
    }
  } : {})
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2021-06-01' = {
  parent: profile
  name: 'sec-${appName}-${environment}'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

output profileId string = profile.id
output endpointId string = endpoint.id
output frontDoorEndpointHostName string = endpoint.properties.hostName

output adminCustomDomainValidationDnsTxtRecordName string = enableCustomDomains ? '_dnsauth.${adminCustomDomain.properties.hostName}' : ''
output adminCustomDomainValidationDnsTxtRecordValue string = enableCustomDomains ? adminCustomDomain.properties.validationProperties.validationToken : ''
output tenantWildcardDomainValidationDnsTxtRecordName string = enableCustomDomains ? '_dnsauth.${tenantWildcardCustomDomain.properties.hostName}' : ''
output tenantWildcardDomainValidationDnsTxtRecordValue string = enableCustomDomains ? tenantWildcardCustomDomain.properties.validationProperties.validationToken : ''

