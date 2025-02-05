<#
.SYNOPSIS
Retrieves the current Kubernetes server version and compares it with the latest stable Kubernetes versions from GitHub.

.DESCRIPTION
The `Get-KubernetesReleaseInfo` function checks the current Kubernetes version deployed using the `kubectl` command 
and fetches the latest stable release versions of Kubernetes available on GitHub.
 It helps users determine if their Kubernetes cluster is up-to-date by comparing their current version
  with the latest releases, excluding pre-releases.

.PARAMETER None
This function does not take any parameters. It retrieves all necessary information internally and displays output directly.

.OUTPUTS
The function writes output to the console showing the current Kubernetes version and a list of newer stable versions available.

.EXAMPLE
Get-KubernetesReleaseInfo

This command fetches the current Kubernetes server version and displays any newer stable versions that are available from GitHub.

.NOTES
- Requires `kubectl` to be installed and configured.
- Internet access is necessary for retrieving release data from GitHub.
- Ensure GitHub's API is accessible in your network environment.

#>

function Get-KubernetesReleaseInfo{
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }

    $currentVersionKubernetes = kubectl version -o json | ConvertFrom-Json
    Write-Host "The current kubernetes version is: $($currentVersionKubernetes.ServerVersion.gitVersion)"
    
    Write-Host "Do you want to retrieve information from Azure or Kubernetes releases Need to write that still"

    # Retrieve Latest Kubernetes Releases
    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/kubernetes/kubernetes/releases' -UseBasicParsing

    # Extract version numbers, excluding any version with a '-'
    $latestVersions = $releases | Where-Object { $_.tag_name -notmatch '-' } | ForEach-Object { $_.tag_name.TrimStart('v') } | Select-Object -First 5

    # Output the latest retrieved versions (showing a few for demonstration)
    Write-Output "Latest Kubernetes Versions (excluding pre-releases):"
    $latestVersions 

    # Compare Versions
    $newerVersions = $latestVersions | Where-Object { [version]$_ -gt [version]$currentVersion }

    # Output the result
    if ($newerVersions) {
        Write-Output "Newer stable Kubernetes versions available: $newerVersions"
    } else {
        Write-Output "Your current version is up to date compared to the latest stable GitHub releases."
    }
}