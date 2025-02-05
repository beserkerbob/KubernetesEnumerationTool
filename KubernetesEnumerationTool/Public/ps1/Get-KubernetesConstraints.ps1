function Get-KubernetesConstraints {
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }
    # Runs kubectl command to get constraint information
    $commandOutput = kubectl get constraints -o=jsonpath="{range .items[*]}{.kind}{'\t'}{.spec.enforcementAction}{'\n'}{end}"
    
    # Process the command output if necessary
    $constraints = $commandOutput -split "`n" | Where-Object { $_ -ne '' }
    
    # Output the results in a friendly table format
    $formattedConstraints = $constraints | ForEach-Object {
        $line = $_ -split "`t"
        [PSCustomObject]@{
            Name               = $line[0]
            EnforcementAction  = $line[1]
        }
    }
    
    $formattedConstraints | Format-Table -AutoSize
}