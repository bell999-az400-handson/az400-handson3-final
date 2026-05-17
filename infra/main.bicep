param location string = resourceGroup().location

resource appPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'az400-app-plan'
  location: location
  sku: {
    name: 'B1'
  }
}

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: 'az400-handson-app'
  location: location
  properties: {
    serverFarmId: appPlan.id
  }
}
