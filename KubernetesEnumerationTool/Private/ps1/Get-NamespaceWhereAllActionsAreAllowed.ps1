function Get-NamespaceWhereAllActionsAreAllowed {
    param(
        [Parameter(Mandatory = $true)]
        [array]$ActionResourcePairs
    )

    # Initialize a variable to store intersected namespaces
    $intersectedNamespaces = @()

    # Iterate over each action-resource pair and validate permissions
    foreach ($pair in $ActionResourcePairs) {
        $action = $pair.Action
        $resource = $pair.Resource
        $namespaces = Get-NamespacesWhereICanPerformAction -Action $action -Resource $resource

        if ($intersectedNamespaces.Count -eq 0) {
            # Initialize the intersected list with the first list
            $intersectedNamespaces = $namespaces
        } else {
            # Intersect with the previous lists
            $intersectedNamespaces = $intersectedNamespaces | Where-Object { $namespaces -contains $_ }
        }

        # If at any point there's no intersection, break early
        if ($intersectedNamespaces.Count -eq 0) {
            break
        }
    }

    # Output the results
    if ($intersectedNamespaces.Count -gt 0) {
        return $intersectedNamespaces
    } else {
        return $null
    }
}