@description('Required. name of the parent API Management service.')
param apiManagementServiceName string

@description('Required. The name of the API.')
param apiServiceName string

@description('Required. contents of the Policy')
param policyXML string

@description('Optional. format of the policy content.')
@allowed([
  'rawxml'
  'rawxml-link'
  'xml'
  'xml-link'
])
param xmlFormat string = 'rawxml'

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

// get existing instance of APIM
resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' existing = {
  parent: service
  name: apiServiceName
}

// add APIs policy
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-01-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: policyXML
    format: xmlFormat
  }
}
