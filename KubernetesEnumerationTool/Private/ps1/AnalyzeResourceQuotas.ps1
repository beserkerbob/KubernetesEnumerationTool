<#
.SYNOPSIS
Analyzes resource quotas for specified or all namespaces in a Kubernetes cluster.

.DESCRIPTION
The `AnalyzeResourceQuotas` function retrieves and evaluates resource quota configurations in Kubernetes namespaces. It examines the presence of limits on CPU, memory, and pod count, assessing compliance with best practices for resource management in Kubernetes environments. The function identifies namespaces lacking these critical constraints and recommends improvements where necessary.

.PARAMETER token
An optional string token for authentication with the Kubernetes API. Use this to ensure secure communication when accessing quota information.

.PARAMETER givenNamespace
A string parameter specifying the namespace to analyze. If not provided, the function defaults to retrieving quota details from all namespaces.

.OUTPUTS
Displays analysis results, highlighting namespaces with and without appropriate resource limits. Provides recommendations for aligning with best practices in resource allocation.

.EXAMPLE
AnalyzeResourceQuotas -givenNamespace "production"

Analyzes resource quotas in the "production" namespace, reporting on the presence or absence of CPU, memory, and pod limits.

.EXAMPLE
AnalyzeResourceQuotas -token "abcd1234"

Conducts a resource quota analysis across all namespaces using the provided token for Kubernetes API access.

.NOTES
- Leverages `Perform-KubectlCommand` to fetch quota data, necessitating accurate token and namespace specification.
- The function assumes JSON parsing capability for interpreting Kubernetes API responses.
- Serves as a proactive tool for enforcing resource management policies and preventing resource contention or exhaustion.

#>

Function AnalyzeResourceQuotas{
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
        $data = Perform-KubectlCommand  -action "get" -type "quota" -namespace $givenNamespace -extracommand '-o jsonpath="{.items[*].spec.hard}"' -token $token 
    }
    # else{
    #     $data = Perform-KubectlCommand -type "quota" -namespace $givenNamespace -extracommand '-A -o jsonpath="{.items[*].spec.hard}"' -token $token 
    # }

     # A custom object to store the results per namespace
     $namespaceQuotaReport = [PSCustomObject]@{
        Namespace     = $givenNamespace
        LimitsSetForMemory     = $true
        LimitsSetForCpu     = $true
        LimitsSetForPods     = $true
    }

    Write-Host "The hard specifications are:"
    Write-Host $data
    Write-Host "performing further analysis"
    $jsonObject = $data | ConvertFrom-Json

    # Check if 'pods' is present
    if ([string]::IsNullOrEmpty($jsonObject.pods)) {
        Write-Host "There is no limit on the amount of pods in namespace: $givenNamespace"-ForegroundColor Red
        $namespaceQuotaReport.LimitsSetForPods = $false
    }
    if([string]::IsNullOrEmpty($($jsonObject.'limits.cpu'))){
        Write-Host "There is no limit on the CPU in namespace: $givenNamespace"-ForegroundColor Red
        $namespaceQuotaReport.LimitsSetForCpu = $false

    }
    if([string]::IsNullOrEmpty($($jsonObject.'limits.memory'))){
        Write-Host "There is no limit on the CPU in namespace: $givenNamespace "-ForegroundColor Red
        $namespaceQuotaReport.LimitsSetForMemory = $false
    }
    if (
        -not [string]::IsNullOrEmpty($jsonObject.pods) -and
        -not [string]::IsNullOrEmpty($jsonObject.'limits.memory') -and
        -not [string]::IsNullOrEmpty($jsonObject.'limits.cpu')
    ) {
        Write-Host "There is a limit on pods, cpu and memory in namespace: $givenNamespace This is best practice" -ForegroundColor Green
        Write-Host "The limits are for CPU:" -NoNewline
        Write-Host "$($jsonObject.'limits.cpu')" -ForegroundColor Green
        Write-Host "The limits are for RAM:" -NoNewline
        Write-Host "$($jsonObject.'limits.Memory')" -ForegroundColor Green
        Write-Host "The limits are for Pods:" -NoNewline
        Write-Host "$($jsonObject.pods)" -ForegroundColor Green
    }
    else{
        Write-Host "There is not a limit on pods and cpu and memory in namespace: $givenNamespace This is could be Improved " -ForegroundColor Red
    }
    return $namespaceQuotaReport
}