<#
.SYNOPSIS
Extracts specific annotations and allocated resource information from Kubernetes nodes.

.DESCRIPTION
The `Get-NodeInformation` function leverages the `kubectl describe nodes` command to retrieve detailed information about the nodes in a Kubernetes cluster. This function filters and captures specific node annotations and details about allocated resources, providing a concise overview of node characteristics and resource usage.

.PARAMETER None
This function does not accept any parameters. It internally executes `kubectl describe nodes` to gather and process node data.

.OUTPUTS
Outputs an array of strings, each containing specific annotations and allocated resource details from the Kubernetes nodes.

.EXAMPLE
Get-NodeInformation

This command runs `Get-NodeInformation`, extracting and displaying specific annotation details and allocated resources from each node in the Kubernetes cluster.

.NOTES
- Requires `kubectl` to be installed and configured to interact with the target Kubernetes cluster.
- This script captures information related to Azure Kubernetes Service (AKS) and general Kubernetes annotations, such as zone, storage tier, image version, and more.
- Assumes the user has the necessary permissions to execute `kubectl describe nodes`.

#>
function Get-NodeInformation{
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }
        # Run `kubectl describe nodes` and capture the output
    $nodesDescription = kubectl describe nodes

    # Initialize an array to store relevant information
    $extractedInfo = @()

    # Boolean flag to track the allocated resources section
    $inAllocatedResourcesSection = $false

    foreach ($line in $nodesDescription) {
        # Extract specific annotations
        if ($line -match "topology.kubernetes.io/zone=" -or
            $line -match "kubernetes.azure.com/storagetier=" -or
            $line -match "kubernetes.azure.com/node-image-version=" -or
            $line -match "kubernetes.azure.com/network-policy=" -or
            $line -match "kubernetes.azure.com/cluster=" -or
            $line -match "beta.kubernetes.io/instance-type=" -or
            $line -match "beta.kubernetes.io/os=" -or
            $line -match "kubernetes.azure.com/mode=" -or
            $line -match "kubernetes.io/hostname=" -or
            $line -match "Kernel Version" -or
            $line -match "OS Image") 
                {
            $extractedInfo += $line.Trim()
        }
        # Check for the start of the "Allocated resources" section
        if ($line -match "Allocated resources:") {
            $inAllocatedResourcesSection = $true
            $extractedInfo += $line.Trim()
            continue
        }

        # Capture the content of the Allocated resources section
        if ($inAllocatedResourcesSection) {
            if ($line.Trim() -eq "") {
                # End the section on a blank line
                $inAllocatedResourcesSection = $false
            } else {
                $extractedInfo += $line.Trim()
            }
        }
    }

    # Output the extracted information
    Write-Host ""
    Write-Host ""
    $extractedInfo | ForEach-Object { Write-Output $_ }
}