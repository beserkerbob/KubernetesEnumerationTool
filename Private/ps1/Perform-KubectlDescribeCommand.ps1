<#
.SYNOPSIS
   Describes details of a Kubernetes role or cluster role using `kubectl describe`.

.DESCRIPTION
   The Perform-KubectlDescribeCommand function retrieves detailed information about a specified role or cluster role in a Kubernetes cluster.
   It provides flexibility to describe roles within a namespace and can be configured to use an access token if required.

.PARAMETER Type
   Specifies the type of the entity to describe (e.g., `role` or `clusterrole`). This is a mandatory parameter.

.PARAMETER Name
   The name of the role or cluster role to describe. This is a mandatory parameter.

.PARAMETER namespace
   The namespace where the role is located. This parameter is optional and is typically used when describing roles (not cluster roles).

.PARAMETER token
   An optional access token for authentication. If provided, it is used to authenticate the kubectl command.

.EXAMPLE
   # Describe a cluster role
   Perform-KubectlDescribeCommand -Type 'clusterrole' -Name 'admin'

.EXAMPLE
   # Describe a role within a namespace using a token
   Perform-KubectlDescribeCommand -Type 'role' -Name 'developer' -namespace 'dev-space' -token 'yourAccessToken'

.NOTES
   - Requires kubectl to be installed and configured in the environment.
   - The output may vary depending on the permissions granted by the token or the context.
   - Ensure token security by handling them appropriately and avoiding logging sensitive information.

#>

Function Perform-KubectlDescribeCommand{
    [CmdletBinding()]
    param(
        # Parameter roleType is mandatory and determines if the role should be ClusterRole or a normal role.
        [Parameter(Mandatory = $true)]
        [String] $Type,

        # Parameter roleName is mandatory and gives metadata for the user.
        [Parameter(Mandatory = $true)]
        [String] $Name,
        
        # Parameter roleName is mandatory and gives metadata for the user.
        [Parameter(Mandatory = $false)]
        [String] $namespace,

        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token
    )
    Write-Debug "Inside function DescribeRoleInformation"
    if([string]::IsNullOrEmpty($token) -and [string]::IsNullOrEmpty($namespace) ){
        Write-Host "describing role without token"
        $DescribedInformation = kubectl describe $Type $Name 2>$null
    }
    elseif([string]::IsNullOrEmpty($token)){
        Write-Host "describing role with token"
        $DescribedInformation = kubectl describe $Type $Name -n $namespace 2>$null
    }
    elseif([string]::IsNullOrEmpty($namespace)){
        $DescribedInformation = kubectl describe $Type $Name --token $token 2>$null
    }
    else{
        $DescribedInformation = kubectl describe $Type $Name -n $namespace --token $token 2>$null
    }
    if ([string]::IsNullOrEmpty($DescribedInformation)) {
        Write-Host "No permissions to retrieve $Type with name $Name in namespace $namespace" -ForegroundColor Red 
        continue
    }
    $DescribedInformation
}