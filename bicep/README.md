# Tips

## export rg=http-test00

## export loc=westeurope

## az deployment group create --resource-group $rg --template-file "./bicep/main.bicep" --parameters "./bicep/main.parameters.json" --confirm-with-what-if

## az group delete -g $rg --yes --no-wait

