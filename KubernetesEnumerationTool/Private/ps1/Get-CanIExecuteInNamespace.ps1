<#
.SYNOPSIS
   Verifies if a specified command can be executed within a specific Kubernetes namespace or across all namespaces.

.DESCRIPTION
   The Get-CanIExecuteInNamespace function utilizes the `kubectl auth can-i` command to determine whether a particular action can be executed inside a given namespace or globally across all namespaces.
   The function supports token-based authentication and can be configured to check a single namespace or evaluate permissions across all namespaces.

.PARAMETER namespace
   The specific namespace to check for command execution capability. Must be provided unless `allNamespaces` is set to true.
   Alias: n

.PARAMETER token
   An optional string containing a token for Kubernetes authentication. Defaults to null if not specified, meaning the default authentication context will be used.
   Alias: t

.PARAMETER command
   A string specifying the command whose executability is being verified. The string will be split into arguments for the `kubectl` command.
   Alias: c

.PARAMETER allNamespaces
   A boolean flag indicating whether to check the command's executability across all namespaces. Defaults to false.
   Alias: A

.OUTPUTS
   Displays whether or not the command can be executed in the specified namespace(s), and returns a boolean result based on the check.

.EXAMPLE
   # Check if you can list pods in the default namespace without using a token
   Get-CanIExecuteInNamespace -n "default" -c "get pods"

.EXAMPLE
   # Check if you can delete deployments across all namespaces with a specific token
   Get-CanIExecuteInNamespace -c "delete deployments" -t "yourAccessTokenHere" -A $true

.NOTES
   Ensure `kubectl` is available and properly configured in your environment. This function depends on the Kubernetes CLI to perform permission checks.

#>
Function Get-CanIExecuteInNamespace{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias("n")]
        [string]$namespace,
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$token = $null,  #Set null as default
        [Parameter(Mandatory = $false)]
        [Alias("c")]
        [string]$command,
        [Parameter(Mandatory = $false)]
        [Alias("A")]
        [boolean]$allNamespaces = $false
    )
    if([string]::IsNullOrEmpty($namespace) -and $allNamespaces -eq $false){
        Write-Host "CanIExecute needs to know a namespace or allNamespaces must be set to true"
    }
    $commandArgs = $command -split ' '
    $canIResult = "no"
    if($allNamespaces){
        # Run the kubectl command and capture the output
        if ([string]::IsNullOrEmpty($token)) {
            $canIResult = & "kubectl" "auth" "can-i" @commandArgs "-A"
        }
        else{
            $canIResult = & "kubectl" "auth" "can-i" @commandArgs "--token" $token "-A"
        }
        if ($canIResult -eq "yes") {
            return $true
        }
        return $false
    }
    # Run the kubectl command and capture the output
    if ([string]::IsNullOrEmpty($token)) {
        Write-Host "Validating permission without token permissions"
        $canIResult = & "kubectl" "auth" "can-i" @commandArgs  "-n" $namespace
    }
    else{
        $canIResult = & "kubectl" "auth" "can-i" @commandArgs  "-n" $namespace "--token" $token
    }
    if ($canIResult -eq "yes") {
        Write-Host "You have permission to perform $command in $namespace" -ForegroundColor Green
        return $true
    }
    return $false
}