<#
.SYNOPSIS
    Retrieves files with a specific extension from the volumes on a specified Kubernetes node.

.DESCRIPTION
    The Get-FileExtensionsFromVolumesInNodes function uses `kubectl` to debug a specified Kubernetes node
    and searches for files with a given extension within the node's volumes. If an access token is provided,
    it is used for authentication.

.PARAMETER namespace
    An optional parameter specifying the namespace context for the operation.

.PARAMETER accesstoken
    An optional security token used to authenticate the Kubernetes API call if required.

.PARAMETER extension
    The file extension to search for in the node's volumes.

.PARAMETER nodeName
    The name of the Kubernetes node to be debugged.

.EXAMPLE
    Get-FileExtensionsFromVolumesInNodes -extension ".log" -nodeName "node-01"

    Retrieves files with the `.log` extension from the volumes on the Kubernetes node named "node-01" without an access token.

.EXAMPLE
    Get-FileExtensionsFromVolumesInNodes -namespace "default" -accesstoken "your-access-token" -extension ".conf" -nodeName "node-02"

    Searches for files with the `.conf` extension in the "default" namespace on the node named "node-02" using the provided access token.
#>

function Get-FileExtensionsFromVolumesInNodes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias("n")]
        [string]$namespace,

        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$accesstoken,

        [Parameter(Mandatory = $true)]
        [Alias("ext")]
        [string]$extension,

        [Parameter(Mandatory = $true)]
        [Alias("node")]
        [string]$nodeName
    )

    # Set base kubectl debug command
    $baseCommand = "kubectl debug node/$nodeName -it -q --image=ubuntu"

    # Append namespace if specified
    if ($namespace) {
        $baseCommand += " -n $namespace"
    }

    # Append access token if specified
    if ($accesstoken) {
        $baseCommand += " --token $accesstoken"
    }

    # Find files with the specified extension
    $searchCommand = "$baseCommand -- find /host/var/lib/kubelet/pods/ -type f -name '*$extension'"
    $ExtensionInVolumes = Invoke-Expression $searchCommand

    foreach ($ExtensionInVolume in $ExtensionInVolumes) {
        Write-Host "Listing extension: $extension from path: $ExtensionInVolume"
        Write-Host ""
        $catCommand = "$baseCommand -- cat $ExtensionInVolume"
        Invoke-Expression $catCommand
        Write-Host ""
    }
}