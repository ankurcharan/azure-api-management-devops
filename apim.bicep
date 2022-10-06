
@description('Required. name of the API Management service.')
param apiManagementServiceName string

@description('Optional. location for all resources')
param location string = resourceGroup().location

@description('Required. the resource ID of a subnet in a virtual network to deploy the API Management service in.')
param subnetResourceId string

@description('Optional. tags for the instance')
param tags object = {}


module apiManagementService 'modules/apiManagement.bicep' = {
	name: apiManagementServiceName
	params: {
		tags: tags
		apiManagementInstanceName: apiManagementServiceName
		location: location
		subnetResourceId: subnetResourceId
		virtualNetworkType: 'External'
	}
}
