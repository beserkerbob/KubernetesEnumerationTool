function Validate-ConstraintAction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContraintName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("deny", "dryrun")]
        [string]$EnforcementAction
    )

    # Get the list of constraints using the previous function
    $constraints = Get-KubernetesConstraints
    
    # Check for a constraint that contains "HostFilesystem" in its name with enforcement "deny"
    $foundConstraint = $constraints | Where-Object {
        $_.Name -like $ContraintName -and $_.EnforcementAction -eq $EnforcementAction
    }

    if ($foundConstraint) {
        Write-Output "Constraint found with name containing $ContraintName and enforcement action $EnforcementAction."
        return $true
    } else {
        Write-Output "No such constraint found."
        return $false
    }
}