<#
.SYNOPSIS
Analyzes Kubernetes pods to identify adherence to best practices concerning security and configuration.

.DESCRIPTION
The `Get-PodBestPracticeAnalysis` function performs an in-depth examination of Kubernetes pod configurations across specified or all namespaces. It uses `AnalyzingOrphanedPods` to evaluate pods against a set of best practices relating to security and operation, including checks for orphaned pods, appropriate security contexts, resource limits, and the use of proper tags. This helps in identifying potential configuration vulnerabilities and compliance with Kubernetes best practices.

.PARAMETER token
An optional authentication token used for Kubernetes API interactions, allowing the function to perform operations that require authenticated access.

.PARAMETER givenNamespace
Specifies a namespace to restrict the analysis to a particular scope within the cluster. If omitted, all accessible namespaces are checked.

.OUTPUTS
Displays detailed analyses of pods that do not meet established Kubernetes best practices, including potential security risks and misconfigurations.

.EXAMPLE
Get-PodBestPracticeAnalysis -givenNamespace "dev"

Analyzes pods within the "dev" namespace, reporting on co
nfigurations that do not align with best practices.

.EXAMPLE
Get-PodBestPracticeAnalysis -token "abcd1234"

Performs a security and configuration check for pods across all namespaces using the provided authentication token.

.NOTES
- Relies on the `AnalyzingOrphanedPods` function to conduct thorough checks for best practice compliance.
- `kubectl` must be configured correctly to allow the function to retrieve pod data.
- Ensure that appropriate permissions are granted for necessary operations within the targeted namespaces.

#>

Function Get-PodBestPracticeAnalysis{
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
        
        # Get all pods in all namespaces with their owner references
        $pods = Perform-KubectlCommand -action "get" -type "pods" -namespace $givenNamespace -extracommand '-o json' -token $token 
        if([string]::IsNullOrEmpty($pods)){
            Write-Host "You have no permissions to retrieve pod information for the namespace: $givenNamespace" -ForegroundColor Red
        }
        else{
            $kubectlObject = $pods | ConvertFrom-Json
            AnalyzingOrphanedPods -KubectlObject $kubectlObject
            continue;
        }
    }
    $pods = Perform-KubectlCommand -action "get" -type "pods" -extracommand '-A -o json' -token $token 
    if([string]::IsNullOrEmpty($pods)){
        Write-Host "You have no permissions to retrieve pod information for all namespaces" -ForegroundColor Red
    }
    else{
        $kubectlObject = $pods | ConvertFrom-Json
        AnalyzePodSecurityAndBestpractices -KubectlObject $kubectlObject
        continue;
    }
    $namespacesArray = Get-NameSpaceArray
    foreach ($ns in $namespacesArray) {
        if(Get-CanIExecuteInNamespace -token $token -namespace $ns -command "get pods"){
            $pods = Perform-KubectlCommand -action "get" -type "pods" -namespace $ns -extracommand '-o json' -token $token
            $kubectlObject = $pods | ConvertFrom-Json
            AnalyzePodSecurityAndBestpractices -KubectlObject $kubectlObject

        }
        else{
            Write-Host "You have no permissions to get pods from namespace: $ns" -ForegroundColor Red
        }
    }
}
