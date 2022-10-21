$location = 'westus'

# Create a RG for testing the modules
$testRg = New-AzResourceGroup -Name 'WebAppBicep-TestModule-RG' -location $location
# Create a RG for the Bicep Registry
$bcRg = New-AzResourceGroup -Name 'BicepRegistry-Demo-RG' -location $location

# Create a new Bicep module registry
$reg = New-AzContainerRegistry -Name "acr$(Get-Random -Maximum 99999)" `
            -ResourceGroupName $bcRg.ResourceGroupName `
            -Location $location `
            -Sku "Basic" `
            -EnableAdminUser:$false

$reg.LoginServer
$reg.LoginServer | Set-Clipboard

# Paste the content of the clipboard as the value of the environment variable AZURE_BR_URI in .github\workflows\CheckPR.yaml
# Example:
# - name: Publish Bicep files to the Bicep registry
#         if: ${{ success() }}
#         env:
#           AZURE_BR_NAME: '<paste the value here>'

# Create a service principal and grant it contributor access to the RGs
$azureContext = Get-AzContext
$servicePrincipal = New-AzADServicePrincipal `
    -DisplayName "WebAppBicep-TestModule" `
    -Role "Contributor" `
    -Scope $testRg.ResourceId

New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $bcRg.ResourceGroupName `
    -RoleDefinitionName "Contributor"


$output = @{
   clientId = $($servicePrincipal.AppId)
   clientSecret = $([System.Net.NetworkCredential]::new('', $servicePrincipal.Secret).Password)
   subscriptionId = $($azureContext.Subscription.Id)
   tenantId = $($azureContext.Tenant.Id)
}

$output | ConvertTo-Json
$output | ConvertTo-Json | Set-Clipboard
# Paste the content of the clipboard in a new GitHub secret called AzCred
