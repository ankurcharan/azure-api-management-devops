# Azure API Management Devops

an example of azure bicep deployment scripts that you can use to automate your api deployment on the api management instance. 

# API Management Automation Using Bicep

I tried to automate API Management automation and came across [Azure API Management DevOps Resource Kit](https://github.com/Azure/azure-api-management-devops-resource-kit) repository on GitHub. It has a creator and extractor tools but has some things broken and not very convenient to work with. 

Here we'll automate the entire API deployment using bicep scripts.

If you're not too familiar with BICEP, you can use the [Microsoft Bicep Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)

## Azure Resource Group 
Create a resource group on [azure portal](https://portal.azure.com/) that you want to deploy APIM into.
I have created `api-devops` resource group.

![screenshot of azure resource group created](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ixhnhc7od0tzcsqh0aj7.png)

## Virtual Network

### Without Virtual Network (VNet)
You can skip the `virtualNetworkConfiguration` and `virtualNetworkType` properties `modules\apiManagement.bicep` when creating the APIM instance. 

For this article, I am going to create this in a private VNet.

### Within Private Virtual Network (VNet)
If you want to use it without VNet, you can skip this section and move to next.

- Create a VNet and a subnet for APIM within the VNet. 
- Created subnet `apim-subnet` in VNet that I will use.
![screenshot of vnet in subnet](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/b680uvzy3xn9bqpwfpf0.png)
- Get the resource id of the subnet using az-cli.
![screenshot of resourceId received from az-cli](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/id2wk8mx2y2ri8rv8uuc.png)
- Copy the `id` (resourceId) of the subnet. You will need it later.

## Bicep Refresher

This is a very basic refresher of what we need. Please refer [Bicep Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) for more in-depth documentation.

- `param <param-name> <param-type>`  
this is to tell that the template accept a parameter `<param-name>` of type `<param-type>`  
Ex. `param x string` - accepts a parameter `x` of type `string`.  
type can be `array`, `object`, `int`, `string`
- `param <param-name> <param-type> = <default-value>`  
if a value is not passed for the parameter, its default value is used.
- `module <symobolic-name> <path-to-file> = <params>`  
we can declare the resources in modules and re-use the module in templates.
- `[for i in list]` - add a for loop to the templates
- `if (condition)` - only deploy resources if condition is true

## Deployment
After each step you can verify your deployment using az-cli.  
`az deployment group create --resource-group api-devops --template-file apim.bicep --parameters ./apim.parameters.json`

![screenshot of terminal using az-cli to deploy resources](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qgptmqqkmj6hrz3p3iyp.png)

## Create APIM Instance
- Check the code at [https://github.com/ankurcharan/azure-api-management-devops/tree/createApim](https://github.com/ankurcharan/azure-api-management-devops/tree/createApim)
- At `modules/apiManagement.bicep` it accepts multiple parameters and then we can create the instance of APIM.
```bicep
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
```
Parameters:
  - name: name of the apim instance
  - location: azure region you want the instance to be created in
  - sku: 
    - capacity: capacity of the sku (number of deployed units of the sku)
    - name: name of the sku
  - properties: 
    - publisherEmail: email of publisher
    - publisherName: name of publisher
    > Note: You can skip the below VNet configurations if you want to use a public facing backend. If you want to use a private VNet then you can use these two configurations.
    - virtualNetworkType: The type of VPN in which API Management service needs to be configured in. None (Default Value) means the API Management service is not part of any Virtual Network, External means the API Management deployment is set up inside a Virtual Network having an Internet Facing Endpoint, and Internal means that API Management deployment is setup inside a Virtual Network having an Intranet Facing Endpoint only.  
    Allowed values are 'External', 'Internal' and 'None'
    - virtualNetworkConfiguration.subnetResourceId: it takes the resource id of the subnet if you want this to have a private vnet. 

With this much you will have an API Management instance running in your resource group. 

- and then we have declared the output values of the instance created  
```bicep
output name string = apiManagementInstanceName
output resourceId string = apiManagementService.id
output apimGatewayUrl string = apiManagementService.properties.gatewayUrl
```

- this module is called at `apim.bicep`
```bicep
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
```
It uses the module we create above to create the APIM instance. And we also get the outputs that we define above that we'll use in next steps.

- Parameters file  
We also have parameters file `apim.parameters.json` which currently only has two parameters.  
`apiManagementServiceName` will be the name of your APIM instance.  
`subnetResourceId` is the resource id of your apim subnet.

- APIM instance created
![screenshot of APIM instance created](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/z20he3gl5fbrvmaxcnlp.png)



## Adding global policy
We will add a global policy that will apply to all APIs in the APIM. 
I have kept it empty and would just forward all requests as it is. You can read more about APIM policies at [https://learn.microsoft.com/en-us/azure/api-management/api-management-policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)

- Check the code at [https://github.com/ankurcharan/azure-api-management-devops/tree/globalPolicy](https://github.com/ankurcharan/azure-api-management-devops/tree/globalPolicy)
- Added a new xml file `policies/global-policy.xml`
this is the global 
- A new step is added at `modules/apiManagement.bicep`
```bicep
resource globalPolicy 'Microsoft.ApiManagement/service/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: apiManagementService
  properties: {
    value: loadTextContent('../policies/global-policy.xml')
    format: 'rawxml'
  }
}
```
  - `parent` is given the APIM instance. it is used to create resource names for ARM templates. You can read more at [https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/child-resource-name-type](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/child-resource-name-type)
  - `format` is the format of the policy. It support different format. We are giving it xml hance `rawxml`
  - `value` is the contents of the policy. `loadtextContent('path/to/file')` is a bicep function that loads the contents of the file to the bicep.
- You can check global policy from Azure portal. Go to `API` from left nav. click on `All APIs`. and that is where your contents of global policy would reflect.

![screenshot of where to check global policy deployed on APIM instance](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/18c48hp2qryvvi6s20xn.jpg)



## Swagger 
- Check the code at [https://github.com/ankurcharan/azure-api-management-devops/tree/swaggerFile](https://github.com/ankurcharan/azure-api-management-devops/tree/swaggerFile)
- Added a swagger specification at `api-spec/jsonplaceholder.json`
- Normally, you would create this file in the build pipeline and then use it to deploy APIs. I have added this explicitly for simplicity.
- Swagger is a api-specification swagger, checkout [swagger.io](https://swagger.io/). And you can have a demo at [https://editor.swagger.io/](https://editor.swagger.io/)

## Adding APIs
- Checkout the code at [https://github.com/ankurcharan/azure-api-management-devops/tree/api](https://github.com/ankurcharan/azure-api-management-devops/tree/api)
- Now here is a new module at `modules/apiManagement.api.bicep`
```bicep
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
```
-  `value` is the api specification content. In our case the swagger file.
-  `format` is the format of the api spec. If its OpenApi3.0 (openapi / openapi+json) or if its Swagger2.0 (swagger-json) of it its link to the swagger.
-  We have used this module in `apim.bicep`
-  There is a new parameter `apiInformation` with default value being arrau of api information objects. You can pass the value of this from parameter file but then you have to serialize the swagger specification file in a string and then pass it. Using bicep, it gives us a function `loadTextContent('path')` which does that for you. And since this is not going to change much if you're doing this for same application. (or multi-region / multi-tenant) than we can use this default value of the parameters. 
- this also has an another resource declaration
```bicep
resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}
```
- `existing` keyword checks for existing resources.
- this checks the api management instance exists with the name `apiManagementServiceName` and then proceed with creating the API.

-  using this module from `apim.bicep` 
```bicep
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
}]
```
- we have traverse on the array of api information and used it to create all the api that are defined in the array. this is useful if you have multiple microservice that you want to expose to the customers and manage through APIM. ie. if you want to add more apis add another item in `apiInformation` array and you're done. 
- `apiInfomation[0]` object is 
```json
{
    apiName: 'json-placeholder'
    apiDisplayName: 'JsonPlaceholder'
    specificationFormat: 'openapi+json'
    suffix: '/jp'
    serviceUrl: 'https://jsonplaceholder.typicode.com/'
    apiSpecContent: loadTextContent('api-spec/jsonplaceholder.json')
}
```
- `apiName` is the name of the api use for referencing it if you want to create products or policies.
- `apiDisplayName` is what you'll see on the portal.
- `specificationFormat` is the format of the api specification.
- `serviceUrl` is the backend url of the service.
- `apiSpecContent` is the specification content of the apis.

- DependsOn - this is an array of resources that you want your currently resource to be deployed after.
```bicep
dependsOn: [
    apiManagementService
]
```
 this means that current resource deployment depends on the resource represented by symbolic name `apiManagementService` (apim instance, cause obviously you'd want to create the APIs only if APIM exists).
- APIs added to APIM instance

![screenshot of APIs deployed and operations added in APIM](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j92pmh2y4lx4473nbtg1.png)

you can also see all the operations are added to APIM.


## Adding API Policy
- You might want to add API specific policies on APIM. 
- Check code at [https://github.com/ankurcharan/azure-api-management-devops/tree/apiPolicy](https://github.com/ankurcharan/azure-api-management-devops/tree/apiPolicy)

- In `apim.bicep` we have added a new line in `apiInformation` to load the contents of the policy.
`policyContents: loadTextContent('policies/apiPolicy-jsonplaceholder.xml')`
- added a new API policy at `policies/apiPolicy-jsonplaceholder.xml`
- added a policy deploymenr module at `modules/apiManagement.api.policy.bicep`
- api policy deploy against a policy so it checks tha particular API exists already in the APIM
```bicep
// checks if API exists
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
```
- notice how we have added `api` as the parent of `apiPolicy`

- this module is used at `apim.bicep`
```bicep
module apiPolicyDeploy 'modules/apiManagement.api.policy.bicep' = [for (config, i) in apiInformation: {
	name: '${i}-${config.apiName}-policy'
	params: {
		apiManagementServiceName: apiManagementServiceName
		apiServiceName: config.apiName
		policyXML: config.policyContents
	}
	dependsOn: [
		apisDeploy
	]
}]
```
- `apiServiceName` is the api name in the APIM instance for which to deploy policies. 
- `policyXML` is the contents of the policy. You can read more about APIM policies at at [https://learn.microsoft.com/en-us/azure/api-management/api-management-policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies).

- You can see the API policy at 

![screenshot of where to check API policy deployed on APIM](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cqvhmfwdbo354t6gyoo5.png)
Whatever policy you have added for your API would be updated here. 

## Final Code
You can browse through the final code at [https://github.com/ankurcharan/azure-api-management-devops/tree/main](https://github.com/ankurcharan/azure-api-management-devops/tree/main)

You can run this template and this would automate your APIM creation and API deployment using Swagger.

Let me know if you want to add more features of the APIM to this template like Products, Subscriptions, Groups, LogAnalytics Workspace etc. 

## Contact
Ankur Charan
LinkedIn: https://www.linkedin.com/in/ankurcharan/  
Instagram: https://www.instagram.com/ankurcharan/ 