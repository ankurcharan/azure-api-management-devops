
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


@description('Optional. Array of API specification and details')
param apiInformation array = [
	{
    apiName: 'json-placeholder'
		apiDisplayName: 'JsonPlaceholder'
		specificationFormat: 'openapi+json'
		suffix: '/jp'
    serviceUrl: 'https://jsonplaceholder.typicode.com/'
		apiSpecContent: loadTextContent('api-spec/jsonplaceholder.json')
	}
]


module apisDeploy 'modules/apiManagement.api.bicep' = [for (config, i) in apiInformation: {
	name: '${i}-${config.apiName}-import-${apiManagementServiceName}'
	params: {
		apiSpecification: config.apiSpecContent
		apiServiceUrl: config.serviceUrl
		apiServiceDisplayName: config.apiDisplayName
		apiServiceName: config.apiName
		suffix: config.suffix
		apiManagementServiceName: apiManagementServiceName
		specificationFormat: config.specificationFormat
	}
	dependsOn: [
		apiManagementService
	]
}]
