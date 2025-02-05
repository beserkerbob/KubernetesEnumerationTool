function Get-NamespacesWhereICanPerformAction {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('get', 'update', 'patch', 'create', 'list', 'exec', 'delete', 'watch', 'debug')]
        [Alias("a")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [Alias("r")]
        [ValidateSet('pods', 'nodes', 'services', 'namespaces', 'pods/exec', 'nodes/debug')]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$token

    )

    if($action -eq "exec" -and $Resource -eq "pods"){
        Write-Host "Validating exec pods"
        $Resource = "pods/exec"
        $Action = "get"
    }
    if($action -eq "debug" -and $Resource -eq "nodes"){
        Write-Host "Validating exec pods"
        $Resource = "nodes/debug"
        $Action = "get"
    }
    # Ensure kubectl is available
    if ((Get-Command kubectl -ErrorAction SilentlyContinue) -eq $null) {
        Write-Error "kubectl is not installed or not in your PATH."
        return
    }

    # Get all namespaces
    $namespaceList = Get-NameSpaceArray

    if (-not $namespaceList) {
        Write-Output "No namespaces found."
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