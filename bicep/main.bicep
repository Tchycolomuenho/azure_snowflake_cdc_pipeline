param location string = 'eastus'
param adfName string = 'adf-cdc-snowflake'
param storageName string = 'cdclanding${uniqueString(resourceGroup().id)}'

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output adfId string = adf.id
output storageId string = storage.id
