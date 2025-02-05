<#
.SYNOPSIS
    Retrieve Rbac rights for the whole cluster or it will iterate for every namespace.
     Possible to include an optional access token of an system account

.DESCRIPTION
    The Get-RBAC function attempts to retrieve RBAC details, such as role bindings, cluster role bindings, 
    cluster roles, and roles from a Kubernetes cluster across all namespaces. 
    It checks permissions for token usage and provides a detailed overview of the roles and role bindings.

.PARAMETER accesstoken
    An optional access token used for authentication to access Kubernetes with elevated permissions.
    If not provided, the function attempts to retrieve information accessible without a access token.

.EXAMPLE
    Get-RBAC

    This example runs the Get-RBAC function without any access token, retrieving RBAC data available 
    without requiring authenticated access.

.EXAMPLE
    Get-RBAC -accesstoken "your-access-token"

    This example provides an access token to the Get-RBAC function, allowing it to retrieve 
    elevated RBAC data from the Kubernetes cluster, where authentication is required.

.EXAMPLE
    Get-RBAC -t "your-access-token"

    Utilizes the alias '-t' to provide an access token for the Get-RBAC function, retrieving elevated RBAC data where authentication is required.

.NOTES
    This function relies on the 'jq' command-line utility for JSON processing. Ensure 'jq' is installed 
    and available in your system's PATH for the function to execute successfully.

    As this function checks cluster-wide permissions first, it handles restricted access by
    iterating over individual namespaces and gathering detailed RBAC information.

    The function uses the Perform-KubectlCommand helper function to execute kubectl calls with
    specified actions and types.

.LINK
    https://jqlang.github.io/jq/download/ - Download page for 'jq', required for JSON processing.
#>

function Get-RBAC {
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [String] $accesstoken
    )
    try { 
        $_ = (Get-Command jq -ErrorAction Stop).Path
     } catch { 
        Write-Host "For this to work jq is required can be installed from https://jqlang.github.io/jq/download/ "
        exit 1
     }
         # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }
     
    Write-Host "Trying to retrieve RBAC information from the kubernetes cluster for all namespaces"
    Write-Host "First trying to Retrieve rolebindings and clusterroleBindings"
    $rbacAllNamespaces = Perform-KubectlCommand -action "get" -type "rolebindings,clusterrolebindings" -Token $accesstoken -extracommand "-A -o wide"
    if ([string]::IsNullOrEmpty($rbacAllNamespaces)) {
        Write-Host "No permissions to perform RBAC on all namespaced" -ForegroundColor Red 
        Write-Host "Performing rolebindings request for each namespace"
        $namespacesArray = Get-NameSpaceArray
        foreach ($namespace in $namespacesArray) {
            $rbacNamespace = Perform-KubectlCommand -action "get" -type "rolebindings" -namespace $namespace -Token $accesstoken -extracommand "-o wide"
            if ([string]::IsNullOrEmpty($rbacNamespace)) {
                    Write-Host "No permissions to retrieve rolebindings on $namespace" -ForegroundColor Red 
                    continue
            }
            Write-Host "Found the following role bindings for $namespace" -ForegroundColor Green
            $rbacNamespace
            Write-Host "Trying to retrieve more information for each Role"
            $rbacJsonNamespace = Perform-KubectlCommand -action "get" -type "rolebindings" -namespace $namespace -Token $accesstoken -extracommand "-o json"
            $rbacRolesOverview = $rbacJsonNamespace | jq '[.items[] | {type: .roleRef.kind, Name: .roleRef.name}]' | ConvertFrom-Json 2>$null
            foreach ($Role in $rbacRolesOverview) {
                # Accessing the 'type' property directly from the hashtable object
                # Make sure the object is parsed correctly
                if ($Role -is [PSCustomObject] -or $Role.PSTypeNames -contains 'PSCustomObject') {
                    if (![string]::IsNullOrEmpty($Role.type)) {
                        DescribeInformation -roleType $Role.type -roleName $Role.name -Token $accesstoken
                    } 
                    else {
                        Write-Host "Error: RoleType is empty or not found"
                    }
                } 
                else {
                    Write-Host "Error: Role structure is not as expected"
                }
            }
        }
    }
    else{
        Write-Host "You have permissions to perform RBAC on all namespaced" -ForegroundColor Green 
        Write-Host ""
        $rbacAllNamespaces
    }
    Write-Host "Trying to retrieve clusterroles"
    $rbacClusterRoles = Perform-KubectlCommand -action "get" -type "clusterroles" -Token $accesstoken
    if ([string]::IsNullOrEmpty($rbacAllNamespaces)) {
        Write-Host "No permissions to retrieve clusteroles on all namespaces" -ForegroundColor Red
    }
    else{
        Write-Host "You have permissions to list clusterroles" -ForegroundColor Green 
        Write-Host ""
        $rbacClusterRoles
    }
    Write-Host "Trying to retrieve roles For all namespaces"
    $rbacRoles =  Perform-KubectlCommand -action "get" -type "roles" -Token $accesstoken
    if ([string]::IsNullOrEmpty($rbacAllNamespaces)) {
        Write-Host "No permissions to retrieve roles on all namespaces" -ForegroundColor Red
        $namespacesArray = Get-NameSpaceArray
        foreach ($namespace in $namespacesArray) {
            $roleNamespace =  Perform-KubectlCommand -action "get" -type "roles" -namespace $namespace -extracommand "-o wide" -Token $accesstoken
            if ([string]::IsNullOrEmpty($roleNamespace)) {
                    Write-Host "No permissions to retrieve role on $namespace" -ForegroundColor Red 
                    continue
            }
            Write-Host "Found at least 1 role for $namespace. The names are:" -ForegroundColor Green
            $roleNames = Perform-KubectlCommand -action "get" -type "roles" -namespace $namespace -extracommand "-o wide" -Token $accesstoken | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0]}
            Write-Host "Trying  to retrieve additional information for this role"
            foreach($role in $roleNames){
               $roleDescription =  DescribeInformation -roleType "role" -roleName $role -n $namespace -Token $accesstoken 2>$null
               if ([string]::IsNullOrEmpty($roleDescription)) {
                    Write-Host "No permissions to describe the role with name: $role in $namespace" -ForegroundColor Red 
                    continue
               }
               $roleDescription
            }
        }
    }
    
}