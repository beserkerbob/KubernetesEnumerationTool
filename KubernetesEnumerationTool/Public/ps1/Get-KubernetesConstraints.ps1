function Get-KubernetesConstraints {
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }
    # Runs kubectl command to get constraint information
    $commandOutput = kubectl get constraints -o=jsonpath="{range .items[*]}{.kind}{'\t'}{.spec.enforcementAction}{'\t'}{.spec.match.excludedNamespaces}{'\n'}{end}"
    
    # Process the command output if necessary
    $constraints = $commandOutput -split "`n" | Where-Object { $_ -ne '' }
    
    # Output the results in a friendly table format
    $formattedConstraints = $constraints | Where-Object { $_ -ne "" } | ForEach-Object {
        $line = $_.Trim() -split "`t"
        if ($line.Count -ge 3) {
            [PSCustomObject]@{
                Name               = $line[0].Trim()
                EnforcementAction  = $line[1].Trim()
                ExcludedNamespaces = $line[2].Trim()
            }
        }
    }
    
     $formattedConstraints | Format-Table -AutoSize
     return $formattedConstraints
}