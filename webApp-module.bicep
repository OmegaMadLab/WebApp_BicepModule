@description('The name of the webapp')
param webAppNamePrefix string

@description('The Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Set to true if you want to create a new app service plan')
param createAppServicePlan bool = true

@description('The existing App Service Plan ID. Mandatory if createAppServicePlan is set to false')
param appServicePlanId string = ''

@allowed([
  'PROD'
  'TEST'
])
@description('The target environment for the deployment')
param environment string

var hostingPlanName = 'hostingPlan-${environment}-${location}'

var webAppName = '${webAppNamePrefix}-${environment}-${location}'

var environmentSettings = {
  TEST: {
      skuName: 'B1'
      skuCapacity: 1
  }
  PROD: {
      skuName: 'S1'
      skuCapacity: 2
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = if (createAppServicePlan) {
  name: hostingPlanName
  location: location
  sku: {
    name: environmentSettings[environment].skuName
    capacity: environmentSettings[environment].skuCapacity
  }
}

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: createAppServicePlan == true ? hostingPlan.id : appServicePlanId
  }
}

output webAppId string  = webApp.id
// output webAppUri string = webApp.properties.defaultHostName
