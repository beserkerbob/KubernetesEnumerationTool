Function Get-ExecutableDeploymentNamespaces {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$access_token = "nvt",
        [Parameter(Mandatory = $false)]
        [string]$deleteRequired = $true
    )
    # Array of action-resource pairs along with exec requirement check
    $actionResourcePairs = @(
        @{ Action = "create"; Resource = "pod" },
        @{ Action = "create"; Resource = "job" },
        @{ Action = "create"; Resource = "replicaset" },
        @{ Action = "create"; Resource = "replicationcontroller" },
        @{ Action = "create"; Resource = "cronjob" },
        @{ Action = "create"; Resource = "daemonset" },
        @{ Action = "create"; Resource = "deployment" }
    )

    # Resulting object to hold actions, allowed namespaces, and exec verification
    $permissionResults = @()

    foreach ($pair in $actionResourcePairs) {
        # Get the allowed namespaces for each action-resource pair
        $allowedNamespaces = Get-NamespaceWhereAllActionsAreAllowed -ActionResourcePairs @($pair)
        
        # Check namespaces with exec permission
        $actionWithExec = @(
            @{ Action = "exec"; Resource = $pair.Resource }
        )
        $execAllowedNamespaces = Get-NamespaceWhereAllActionsAreAllowed -ActionResourcePairs $actionWithExec
        if($deleteRequired){
            # Check namespaces with delete permission
            $actionWithdelete= @(
                @{ Action = "delete"; Resource = $pair.Resource }
            )
            $deleteAllowedNamespaces = Get-NamespaceWhereAllActionsAreAllowed -ActionResourcePairs $actionWithdelete
            write-Host delete is allowed namespaces $deleteAllowedNamespaces
        }

        # Add to a custom object
        $result = [PSCustomObject]@{
            ActionResource = $pair.Resource
            AllowedNamespacesToCreate = $allowedNamespaces
            AllowedNamespacesToExec = $execAllowedNamespaces
            AllowedNamespacesToDelete = $deleteAllowedNamespaces
            DeleteRequired = $deleteRequired 
        }

        $permissionResults += $result
    }
    Write-Host $permissionResults | Format-Table -AutoSize
    # Display the result
    return $permissionResults
}