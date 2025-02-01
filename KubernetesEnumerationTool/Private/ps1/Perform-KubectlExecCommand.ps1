<#
.SYNOPSIS
   Executes a command inside a Kubernetes pod using kubectl exec.

.DESCRIPTION
   The Perform-KubectlExecCommand function facilitates executing commands within a specified Kubernetes pod.
   It supports authentication using tokens and provides options for detailed debugging output.

.PARAMETER pod
   The name of the pod in which to execute the command.
   Alias: p

.PARAMETER namespace
   The namespace where the pod is located.
   Alias: n

.PARAMETER command
   The command to execute inside the pod. This is a mandatory parameter and should be the full command as a string.
   Alias: c

.PARAMETER accesstoken
   An access token used for Kubernetes authentication. If not provided, the function attempts to execute the command
   without token authentication.
   Alias: t

.EXAMPLE
   # Example without access token
   Perform-KubectlExecCommand -p 'my-pod' -n 'default' -c 'ls /app'

   # Example with access token
   Perform-KubectlExecCommand -p 'my-pod' -n 'default' -c 'ls /app' -t 'yourAccessToken'

.NOTES
   - This function requires kubectl to be installed and properly configured on the system where the script runs.
   - To troubleshoot or validate command executions, use -Verbose for more detailed output.
   - Ensure token security by handling tokens appropriately and avoiding logging sensitive details.

#>

function Perform-KubectlExecCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('p')]
        [string]$pod,
        [Parameter(Mandatory = $true)]
        [Alias('n')]
        [string]$namespace,
        [Parameter(Mandatory = $true)]
        [Alias('c')]
        [string]$command,
        [Parameter(Mandatory = $false)]
        [Alias('t')]
        [string]$accesstoken
    )
    $commandArgs = $command -split ' '
    if ([string]::IsNullOrEmpty($accesstoken)) {
        Write-Host "Validating permission without token permissions"
        return kubectl exec -it $pod -n $namespace -- @commandArgs 2>$null 
    } else {
        Write-Debug "Command arguments: $($commandArgs -join ', ')"
        Write-Debug "kubectl exec -it $pod -n $namespace --token $token -- $($commandArgs -join ' ')"
        return kubectl exec -it $pod -n $namespace --token $accesstoken -- @commandArgs 2>$null 
    }
}