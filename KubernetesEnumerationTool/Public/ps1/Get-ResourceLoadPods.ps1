<#
.SYNOPSIS
    Retrieves resource usage statistics for all pods across specified or all namespaces in a Kubernetes cluster.

.DESCRIPTION
    The Get-ResourceLoadPods function collects and displays the resource usage of all pods, optionally for a specific namespace. 
    The function utilizes a token for accessing restricted data if provided, and it attempts to sort pod data by memory usage.

    When a namespace is specified, the function focuses on that particular namespace. 
    If the namespace is omitted, it attempts to gather data from all namespaces, provided the token allows such access.

.PARAMETER namespace
    An optional parameter specifying the namespace to focus on. If omitted, the function will attempt 
    to gather data from all namespaces.

.PARAMETER accesstoken
    An optional access token enabling the function to retrieve data with elevated permissions, 
    allowing access to potentially restricted information.

.NOTES
    The function uses other utilities or functions such as 'Perform-KubectlCommand' and 'Can-I-ExecuteInNamespace'.
    Ensure these utilities or modules are correctly imported and configured before running this function.

    The function sorts pod data by various resource parameters such as memory and CPU usage when retrieving statistics.

.EXAMPLE
    Get-ResourceLoadPods -namespace "default"

    Retrieves resource usage information for all pods in the "default" namespace, if accessible.

.EXAMPLE
    Get-ResourceLoadPods -accesstoken "your-access-token"

    Attempts to gather resource usage statistics for all pods across all namespaces using the given access token.
#>

function Get-ResourceLoadPods{  
    [CmdletBinding()]
param(
    # Parameter roleName is mandatory and gives metadata for the user.
    [Parameter(Mandatory = $false)]
    [Alias("n")]
    [String] $namespace,

    # Parameter token is optional and can be used for acessing with other access_tokens
    [Parameter(Mandatory = $false)]
    [Alias("t")]
    [String] $accesstoken
    )
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }
    if([string]::IsNullOrEmpty($namespace)){
        Write-host "Trying to retrieve resource information for everypod in all namespaces"
        if(Get-CanIExecuteInNamespace -token $accesstoken -command "top pod" -allNamespaces $true){
            Write-host "Allowed to retrieve all pod information from tokens"
            $resourcesUsedNamespace = Perform-KubectlCommand -action "top" -type "pod" -token $accesstoken -namespace $namespace -extracommand "--containers=true --sort-by=memory -A" 
            $resourcesUsedNamespace | Format-Table -Property Name, CPU, Memory
        }
        if([string]::IsNullOrEmpty($resourcesUsedNamespace)){
            Write-Host "Wasn't able to retrieve resource information for everypod"
            $namespacesArray = Get-NameSpaceArray
            foreach ($namespace in $namespacesArray) {
                Write-Host "Listing all pod Resource information, including all containers and sorting it by Memory in namespace: $namespace" -ForegroundColor Green
                $resourcesUsedNamespace = Perform-KubectlCommand -action "top" -type "pod" -token $accesstoken -namespace $namespace -extracommand "--containers=true --sort-by=memory" 
                
                if ([string]::IsNullOrEmpty($resourcesUsedNamespace)) {
                        Write-Host "No permissions to retrieve pod resources in $namespace" -ForegroundColor Red 
                        continue;
                }
                else{
                    $resourcesUsedNamespace 
                }
                Write-Host "Listing all pod Resource information, including all containers and sorting it by CPU in namespace: $namespace" -ForegroundColor Green
                if ([string]::IsNullOrEmpty($resourcesUsedNamespace)) {
                    Write-Host "No permissions to retrieve pod resources on $namespace" -ForegroundColor Red 
                    continue;
                }
                else{
                    $resourcesUsedNamespace 
                }
            }
        }
    }
   
}