function Get-FirstitemWhereICanCreateOrExecInANamespace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$deleteRequired = $true
    )
    $permissionResults = Get-ExecutableDeploymentNamespaces -deleteRequired $deleteRequired 
    Write-Host $permissionResults
    Write-Host "Permission Results: $permissionResults"

    # Initialize variables to hold the result
    $actionWithPermissions = $null    
    # Iterate over each entry and apply the filtering logic
    foreach ($entry in $permissionResults) {
        # Find common namespaces where exec is allowed
        $commonNamespacesForExec = $entry.AllowedNamespacesToCreate | Where-Object { $entry.AllowedNamespacesToExec -contains $_ }

        # If delete is required, further filter these namespaces
        if ($deleteRequired) {
            $commonNamespacesForExecAndDelete = $commonNamespacesForExec | Where-Object { $entry.AllowedNamespacesToDelete -contains $_ }

            if ($commonNamespacesForExecAndDelete -ne $null -and $commonNamespacesForExecAndDelete.Count -gt 0) {
                # Pick the first match
                $actionWithPermissions = [PSCustomObject]@{
                    ActionResource = $entry.ActionResource
                    Namespace = $commonNamespacesForExecAndDelete[0]
                    ExecAllowed = $true
                    DeleteAllowed = $true
                    NeitherExecNorDeleteAllowed = $false
                    deleteRequired = $deleteRequired
                }
                break
            }
        } else {
            if ($commonNamespacesForExec -ne $null -and $commonNamespacesForExec.Count -gt 0) {
                # Pick the first match
                $actionWithPermissions = [PSCustomObject]@{
                    ActionResource = $entry.ActionResource
                    Namespace = $commonNamespacesForExec[0]
                    ExecAllowed = $true
                    DeleteAllowed = $false
                    NeitherExecNorDeleteAllowed = $false
                    deleteRequired = $deleteRequired

                }
                break
            }
        }
    }

    # Additionally, determine if there is no exec or delete allowed when required
    if ($actionWithPermissions -eq $null) {
    foreach ($entry in $permissionResults) {
        $noExecOrDeleteAllowedNamespaces = $entry.AllowedNamespacesToCreate | Where-Object { 
            -not ($entry.AllowedNamespacesToExec -contains $_) -and 
            (-not $deleteRequired -or -not ($entry.AllowedNamespacesToDelete -contains $_))
        }
        
        if ($noExecOrDeleteAllowedNamespaces -ne $null -and $noExecOrDeleteAllowedNamespaces.Count -gt 0) {
            $actionWithPermissions = [PSCustomObject]@{
                ActionResource = $entry.ActionResource
                Namespace = $noExecOrDeleteAllowedNamespaces[0]
                ExecAllowed = $false
                DeleteAllowed = $false
                NeitherExecNorDeleteAllowed = $true
                deleteRequired = $deleteRequired
            }
            break
        }
    }
}


    
    # Display the result based on the findings
    if ($actionWithPermissions -ne $null) {
        Write-Host "First action-resource with required permissions:" -ForegroundColor Green
        $actionWithPermissions
        return $actionWithPermissions
    } else {
        Write-Host "No permissions found for the specified conditions." -ForegroundColor Red
        return $null
    }
}