<#
.SYNOPSIS
   Analyzes Kubernetes permissions and optionally initiates the creation of service accounts, roles, and role bindings.

.DESCRIPTION
   The Get-AnalyzedOutputCanIList function inspects a set of permissions related to Kubernetes resources by evaluating specific verbs and resources.
   If it detects sufficient permissions for managing roles and service accounts and the parameter to create resources is enabled, it initiates the CreateMasterServiceAccount function.

.PARAMETER CanIListOutput
   An object representing the permissions output to be analyzed. Each line of this object should specify resources and permissible actions.

.PARAMETER access_token
   An optional string containing an access token to authenticate when invoking the CreateMasterServiceAccount function.

.PARAMETER DoICreateMasterServiceAccount
   A boolean flag indicating whether to create a master service account along with associated roles and bindings. Defaults to $False.

.NOTES
   Make sure that the CreateMasterServiceAccount function is defined and accessible if the function decides to create the specified resources.

.OUTPUTS
   Outputs each relevant permission line to the console, where lines that meet all conditions are highlighted in green and others in yellow for additional visibility.
   Executes the resource creation block if all conditions and the creation flag evaluate to true.

.EXAMPLE
   $permissions = Get-PermissionsOutput
   Get-AnalyzedOutputCanIList -CanIListOutput $permissions -access_token 'yourAccessToken' -DoICreateMasterServiceAccount $true

#>
Function Get-AnalyzedOutputCanIList{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param(
        [Parameter(Mandatory = $true)]
        [Object]$CanIListOutput,
        [Parameter(Mandatory = $false)]
        [String]$access_token,
        [Parameter(Mandatory = $false)]
        [Bool]$DoICreateMasterServiceAccount = $False
    )

    $rolebinding = $false
    $role = $false
    $serviceAccount = $false
    $CanIListOutput | ForEach-Object {
        # Assuming $entry.Verbs is a string in the format: "[verb1 verb2 verb3]", convert it to an array
        $verbs = $_.Verbs -replace '^\[|\]$', '' -split '\s+'
        # Check if verbs contain *, create, impersonate, or delete
        if ($verbs -contains '*' -or $verbs -contains 'create' -or $verbs -contains 'impersonate' -or $verbs -contains 'delete' -or
            $verbs -contains 'update'  -or $verbs -contains 'patch') {
            # Output the entire line if the conditions are met
            if( $_.Resources -contains 'serviceaccounts' -or
                $_.Resources -contains 'roles.rbac.authorization.k8s.io' -or
                $_.Resources -contains "rolebindings.rbac.authorization.k8s.io" -or
                $_.Resources -contains "azurekeyvaultsecrets.spv.no" -or
                $_.Resources -contains "networkpolicies" -or
                $_.Resources -contains "*" -or
                $_.Resources -contains "secrets"){
                Write-Host $_ -ForegroundColor Green
            }
            else{
                Write-Host $_ -ForegroundColor Yellow
            }
            if( $_.Resources -contains "rolebindings.rbac.authorization.k8s.io"){
                $rolebinding = $true
            }
            if($_.Resources -contains 'roles.rbac.authorization.k8s.io'){
                $role = $true
            }
            if($_.Resources -contains 'serviceaccounts' ){
                $serviceAccount = $true  
            }

        }

    }
        
    if($serviceAccount -eq $true -and $role -eq $true -and $rolebinding -eq $true -and $DoICreateMasterServiceAccount -eq $true){
        CreateMasterServiceAccount -n $namespace -access_token $access_token
    }
}