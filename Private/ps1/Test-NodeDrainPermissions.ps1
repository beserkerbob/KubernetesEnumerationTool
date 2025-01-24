<#
.SYNOPSIS
Checks if the necessary permissions are available to drain nodes in a Kubernetes cluster.

.DESCRIPTION
The `Test-NodeDrainPermissions` function verifies whether the current user or service account has the required permissions to perform node draining operations in a Kubernetes cluster. It assesses access rights to execute necessary commands, such as evicting pods and managing node states, which are critical for safely draining a node.

.PARAMETER token
An optional string token used for Kubernetes API authentication. If specified, this token will be used to authenticate and check permissions.

.OUTPUTS
Displays a message indicating whether the user has the required permissions to drain nodes or not.

.EXAMPLE
Test-NodeDrainPermissions

Checks if the current user has the permissions needed to perform a `kubectl drain <node>` operation.

.EXAMPLE
Test-NodeDrainPermissions -token "abcd1234"

Uses the specified token to determine if sufficient permissions are available for node draining.

.NOTES
- Requires existing permissions to query access rights in the cluster.
- Useful in determining preparatory steps before executing node maintenance or upgrades.
- This is a readonly operation to verify permissions; it does not perform node draining.

#>
function Test-NodeDrainPermissions
{
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token
    )

    if(Get-CanIExecuteInNamespace -command "create pods --subresource=eviction" -token $token -and Get-CanIExecuteInNamespace -command "get pods" -token $token  -and Get-CanIExecuteInNamespace -command "list pods" -token $token -and Get-CanIExecuteInNamespace -command "get nodes" -token $token -and Get-CanIExecuteInNamespace -command "patch nodes" -token $token -and Get-CanIExecuteInNamespace -command "get statefulsets" -token $token -and Get-CanIExecuteInNamespace -command "list statefulsets" -token $token -and Get-CanIExecuteInNamespace -command "get daemonsets " -token $token ){
        Write-Host "Based on access rights you should be able to drain host by performing kubectl drain <node>"
    }
    else{
        Write-Host "Not able to drain hosts"

    }

}