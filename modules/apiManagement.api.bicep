@description('Required. The name of the parent API Management service.')
param apiManagementServiceName string

@description('Required. The FQDN of the backend (host) for the API.')
param apiServiceUrl string

@description('Required. name of the api service. (settings > name)')
param apiServiceName string

@description('Required. display name of the APIs.')
param apiServiceDisplayName string

@description('Optional. description of the APIs.')
param apiServiceDescription string = ''

@description('''
  Required. if not defaulting to OpenApi 3 Specification.
  The format of the specification (swagger) doc
  Example: openapi, openapi+json, openapi+json-link, openapi-link, swagger-json, swagger-link-json
''')
@allowed([
  'graphql-link'
  'openapi'
  'openapi+json'
  'openapi+json-link'
  'openapi-link'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wadl-xml'
  'wsdl'
  'wsdl-link'
])
param specificationFormat string = 'openapi+json'

@description('Required. content value when importing an API.')
param apiSpecification string

@description('Required. suffix of the APIs')
param suffix string

@allowed([
  'https'
  'wss'
])
param protocol string = 'https'

// gets existing instance of APIM
resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

// adds APIs into APIM from swagger or openapi specification
resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  parent: service
  name: apiServiceName
  properties: {
    description: apiServiceDescription
    type: 'http'
    isCurrent: true
    subscriptionRequired: false
    displayName: apiServiceDisplayName
    serviceUrl: apiServiceUrl
    path: suffix
    protocols: [
      protocol
    ]
    value: apiSpecification
    format: specificationFormat
    apiType: 'http'
  }
}
