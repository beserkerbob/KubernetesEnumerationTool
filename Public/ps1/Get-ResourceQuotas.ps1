<#
.SYNOPSIS
Examines and reports on resource quotas across specified or all namespaces within a Kubernetes cluster.

.DESCRIPTION
The `Get-ResourceQuotas` function retrieves resource quota configurations for Kubernetes namespaces, validating permissions and performing detailed analysis with the `AnalyzeResourceQuotas` function. The function primarily uses the `kubectl` command to gather JSON data on resource limits or indications of absence in terms of pods, CPU, and memory. This insight aids in identifying namespace configurations that adhere to best practices or those needing improvement.

.PARAMETER token
An optional string used for authentication with an access token. It facilitates authenticated communication with the Kubernetes API.

.PARAMETER givenNamespace
Specifies a single namespace to target for resource quota analysis. If not provided, the function examines all namespaces available to the user.

.OUTPUTS
Displays information regarding the presence or absence of resource quota limits for pods, CPU, and memory, alongside an overall best practice assessment.

.EXAMPLE
Get-ResourceQuotas

Executes resource quota analysis across all namespaces the user has access to, checking for best practice adherence in quota settings.

.EXAMPLE
Get-ResourceQuotas -token "abcd1234"

Uses the provided access token to authenticate and retrieve resource quota details for each namespace.

.EXAMPLE
Get-ResourceQuotas -givenNamespace "staging"

Analyzes the "staging" namespace specifically to evaluate its resource quota settings against established best practices for Kubernetes.

.NOTES
- Requires execution of `kubectl`, configured appropriately to interact with your targeted cluster.
- The `AnalyzeResourceQuotas` function manages the core analysis, emphasizing the importance of setting quota limits on pods, CPU, and memory.
- Users should ensure they have permissions required for listing and analyzing resource quotas within Kubernetes namespaces.

#>

Function Get-ResourceQuotas{
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token,
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $givenNamespace
    ) 
    if(-not [string]::IsNullOrEmpty($givenNamespace)){
        
        if(Get-CanIExecuteInNamespace -token $token -namespace $givenNamespace -command "get ResourceQuota"){
            AnalyzeResourceQuotas -givenNamespace $givenNamespace
            continue;
        }
        else{
            Write-Host "You have no permissions to list resourcequotas in namespace: $givenNamespace" -ForegroundColor Red
        }
    }

    $namespacesArray = Get-NameSpaceArray
    foreach ($ns in $namespacesArray) {
        if(Get-CanIExecuteInNamespace -token $token -namespace $ns -command "get ResourceQuota"){
            AnalyzeResourceQuotas -givenNamespace $ns -token $token
        }
        else{
            Write-Host "You have no permissions to list resourcequotas in namespace: $ns" -ForegroundColor Red
        }
    }
}