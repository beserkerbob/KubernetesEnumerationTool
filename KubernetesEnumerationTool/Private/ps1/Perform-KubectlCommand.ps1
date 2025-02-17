<#
.SYNOPSIS
    Executes a kubectl command with optional namespace and token parameters.

.DESCRIPTION
    The Perform-KubectlCommand function constructs and executes a kubectl command based on the specified parameters.
    It supports optional namespace and token parameters for targeting specific Kubernetes namespaces and for authentication.
    This function handles combinations of missing tokens or namespaces gracefully and provides informative output.

.PARAMETER Type
    The resource type to operate on (e.g., pods, services).

.PARAMETER Action
    The kubectl action to perform (e.g., get, describe).

.PARAMETER Namespace
    The namespace within which to execute the command. This parameter is optional.

.PARAMETER ExtraCommand
    Additional command arguments to pass to kubectl. This parameter is optional.

.PARAMETER Token
    A token for authentication. This parameter is optional.

.EXAMPLE
    Perform-KubectlCommand -Type "pods" -Action "get" -Namespace "default"

    This example runs the kubectl get command for pods in the "default" namespace.

.EXAMPLE
    Perform-KubectlCommand -Type "services" -Action "describe" -ExtraCommand "--selector app=myapp" -Token "your-token"

    This example describes services with a specific label selector using a token for authentication.
#>


function Perform-KubectlCommand {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true)]
        [alias("Ty")]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [alias("A")]
        [string]$Action,
        [Parameter(Mandatory = $false)]
        [alias("n")]
        [string]$Namespace,
        [Parameter(Mandatory = $false)]
        [alias("ec")]
        [string]$ExtraCommand,
        [Parameter(Mandatory = $false)]
        [alias("t")]
        [string]$Token
    )

    # Split extracommand into an array of arguments.
    $commandArgs = $ExtraCommand -split ' '
    if ([string]::IsNullOrEmpty($Token) -and [string]::IsNullOrEmpty($Namespace)) {
        Write-Host trying to retrieve information without token permissions
        return kubectl $Action $Type @commandArgs  2>$null  
    } 
    elseif ([string]::IsNullOrEmpty($Token)) {
        Write-Host trying to retrieve information without token permissions
        return kubectl $Action $Type -n $Namespace @commandArgs  
    }
    elseif ([string]::IsNullOrEmpty($Namespace)) {
        Write-Host trying to retrieve information with token without a specified namespace
        return kubectl $Action $Type @commandArgs --token $Token 2>$null 
    }
    else {
        Write-Debug Command arguments $($commandArgs -join ', ')
        return kubectl $Action $Type -n $Namespace @commandArgs --token $Token 2>$null 
    }
}