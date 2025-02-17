Function Get-MostRecentRunningPodByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$namespace ,
        [Parameter(Mandatory = $true)]               # Replace with your default namespace or pass it as a parameter
        [string]$podNameSubstring
    )

    $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
    Write-Host $pods 
    $matchingPods = $pods.items | Where-Object {
        $_.metadata.name -like "*$podNameSubstring*" -and $_.status.phase -eq "Running"
    }
    Write-Host "Matching pods: $matchingPods"
    $recentRunningPod = $matchingPods |
        Sort-Object { $_.metadata.creationTimestamp } -Descending |
        Select-Object -First 1

    if ($recentRunningPod) {
        Write-Host "Most recently created and running pod with name containing '$podNameSubstring':"
        Write-Host $recentRunningPod.metadata.name
        Write-Host "Creation Timestamp: $($recentRunningPod.metadata.creationTimestamp)"
        return $recentRunningPod
    } else {
        Write-Host "No running pods found with name containing '$podNameSubstring'."
        return $null
    }
}
