<#
.SYNOPSIS
Retrieves secrets from specified or all namespaces within a Kubernetes cluster.

.DESCRIPTION
The `Get-KubernetesSecrets` function attempts to obtain a list of secrets from a specified namespace or all namespaces within a Kubernetes cluster. Utilizing the Kubernetes API, it verifies permissions and retrieves secret details. If unable to access secrets due to permission restrictions, it iterates over available namespaces to perform individual queries.

.PARAMETER token
An optional string token used for authentication with the Kubernetes API, enabling the function to execute secure API requests.

.PARAMETER givenNamespace
A string specifying the namespace from which to retrieve secrets. If omitted, the function attempts to gather secrets from all namespaces.

.OUTPUTS
Displays a list of secrets available within accessible namespaces, with permissions verified before retrieval attempts.

.EXAMPLE
Get-KubernetesSecrets -givenNamespace "operations"

Retrieves all secrets from the "operations" namespace.

.EXAMPLE
Get-KubernetesSecrets -token "yourTokenValue"

Uses the provided token to authenticate and attempt retrieval of secrets across all namespaces.

.NOTES
- Requires `Perform-KubectlCommand` and `performGetSecretsCommand` functions to facilitate interaction with the Kubernetes API.
- Ensure you have appropriate permissions to access namespaces and their secrets.

#>
Function Get-KubernetesSecrets{
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token,
        [Parameter(Mandatory = $false)]
        [string]$givenNamespace
    )
    if([string]::IsNullOrEmpty($Givenamespace)){
        Write-Host "Trying to retrieve all secrets from all namespaces"
        $GetSecrets = Perform-KubectlCommand -action "get" -type "secrets" -extracommand '-A -o wide' -token $token 
    }
    else{
        Write-Host "Trying to retrieve all secrets from the namespace $Givenamespace"
        $GetSecrets = Perform-KubectlCommand -action "get" -type "secrets" -namespace $Givenamespace -extracommand '-o wide' -token $token 
    }
    if ([string]::IsNullOrEmpty($GetSecrets) -and [string]::IsNullOrEmpty($givenNamespace)) {
        Write-Host "No permissions to retrieve all secrets for all namespaces or from provided namespace" -ForegroundColor Red 
        $namespacesArray = Get-NameSpaceArray
        foreach ($namespace in $namespacesArray) {
            performGetSecretsCommand -token $token -givenNamespace $namespace
        }
    }
    if ([string]::IsNullOrEmpty($GetSecrets)){
        performGetSecretsCommand -token $token -givenNamespace $givenNamespace
    }
    else{
        Write-Host "We have permissions to list all secrets listing content below"
        $GetSecrets
        SearchingSecrets -token $token -allNameSpaces "yes"
    }
}