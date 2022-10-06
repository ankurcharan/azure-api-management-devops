
@description('Required. name of the api management instance.')
param apiManagementInstanceName string

@description('Required. location of the api management instance.')
param location string

@description('Optional. pricing tier of the API Management service.')
@allowed([
  'Basic'
  'Consumption'
  'Developer' 
  'Isolated'  
  'Premium' 
  'Standard'
])
param sku string = 'Premium'

@description('Optional. instance size of the API management service.')
@allowed([
  0
  1 
  2
])
param skuCount int = 1

@description('Required. the full resource ID of a subnet in a virtual network to deploy the API Management service in.')
param subnetResourceId string

@description('Required. The type of VPN in which API Management service needs to be configured in. None (Default Value) means the API Management service is not part of any Virtual Network, External means the API Management deployment is set up inside a Virtual Network having an Internet Facing Endpoint, and Internal means that API Management deployment is setup inside a Virtual Network having an Intranet Facing Endpoint only.')
@allowed([
  'External'
  'Internal'
  'None'
])
param virtualNetworkType string

@description('Optional. tags for the resources')
param tags object = {}

// creates APIM instance
resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementInstanceName
  location: location
  tags: tags
  sku: {
    capacity: skuCount
    name: sku
  }
  properties: {
    publisherEmail: 'ankurcharan@outlook.com'
    publisherName: 'Ankur Charan'
    virtualNetworkConfiguration: {
      subnetResourceId: subnetResourceId
    }
    virtualNetworkType: virtualNetworkType
  }
}

output name string = apiManagementService.name
output resourceId string = apiManagementService.id
output apimGatewayUrl string = apiManagementService.properties.gatewayUrl


resource globalPolicy 'Microsoft.ApiManagement/service/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: apiManagementService
  properties: {
    value: loadTextContent('../policies/global-policy.xml')
    format: 'rawxml'
  }
}
