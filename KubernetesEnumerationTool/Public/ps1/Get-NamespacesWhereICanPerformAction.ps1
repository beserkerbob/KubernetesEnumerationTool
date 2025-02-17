function Get-NamespacesWhereICanPerformAction {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('get', 'update', 'patch', 'create', 'list', 'exec', 'delete', 'watch', 'debug', 'pods/exec')]
        [Alias("a")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [Alias("r")]
        [ValidateSet('pod', 'pods', 'nodes', 'services', 'namespaces', 'pods/exec', 'deployment',  'nodes/debug', 'statefulset', 'daemonset', 'cronjob', 'job', 'replicationcontroller', 'replicaset')]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$token

    )

    if($Action -eq "exec" -and $Resource -eq "pods"){
        $Resource = "pods/exec"
        $Action = "get"
    }
    if($Action -eq "debug" -and $Resource -eq "nodes"){
        $Resource = "nodes/debug"
        $Action = "get"
    }
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }

    # Get all namespaces
    $namespaceList = Get-NameSpaceArray

    if (-not $namespaceList) {
        Write-Host "No namespaces found."
        return
    }
    # List to store namespaces where the action is allowed
    $allowedNamespaces = @()

    # Check permissions across all namespaces
    foreach ($namespace in $namespaceList) {
        $canPerformAction = & kubectl auth can-i $Action $Resource -n $namespace
        if ($canPerformAction -eq 'yes') {
            $allowedNamespaces += $namespace
        }
    }

    if ($allowedNamespaces.Count -gt 0) {
        Write-Host "You can perform '$Action' in the following namespaces:"
        $allowedNamespaces | ForEach-Object { Write-Host "- $_" }
    } else {
        Write-Host "You cannot perform '$Action' in any namespace."
    }
    return $allowedNamespaces;
}