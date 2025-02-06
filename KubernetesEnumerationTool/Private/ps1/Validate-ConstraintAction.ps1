function Validate-ConstraintAction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConstraintName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("deny", "dryrun")]
        [string]$EnforcementAction,
        [Parameter(Mandatory = $false)]
        [string[]]$NamespacesToCheck
    )
    # Get the list of constraints using the previous function
    $constraints = Get-KubernetesConstraints
     # Initialize an array to hold namespaces without the constraint
    $namespacesWithoutConstraint = @()

    # Iterate over each namespace to check
    # Split the string into an array using space as the delimiter
    $NamespacesToCheck = $NamespacesToCheck -split ' '
    foreach ($namespace in $NamespacesToCheck) {
        $namespaceFound = $false
        # Check each constraint to see if it matches the namespace
        foreach ($constraint in $constraints) {
            # Access and output each property of the current constraint
            if([string]::IsNullOrEmpty($constraint.Name)){
                continue;
            }
            $excludedNamespaces = (ConvertFrom-Json -InputObject $constraint.ExcludedNamespaces)
            if ($constraint.Name -eq $ConstraintName -and $constraint.EnforcementAction -eq $EnforcementAction -and $excludedNamespaces -contains $namespace) {
                $namespaceFound = $true
                break
            }
            
        }
        if ($namespaceFound) {
            $namespacesWithoutConstraint += $namespace
        }
    }

# Output the list of namespaces without the constraint
return $namespacesWithoutConstraint
}