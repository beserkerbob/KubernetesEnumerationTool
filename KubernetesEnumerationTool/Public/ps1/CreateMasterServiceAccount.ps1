<#
.SYNOPSIS
   Automates the creation of a Kubernetes service account, role, and role binding within a specified namespace. Which have all rights for that specific namespace

.DESCRIPTION
   The CreateMasterServiceAccount function provides a streamlined way to manage role-based access control in Kubernetes.
   It prompts for role, service account, and role binding names, then creates and verifies these resources within the specified namespace.
   Additionally, it requires an optional access token for authentication against the Kubernetes cluster.

.PARAMETER namespace
   The namespace within which the service account, role, and role binding will be created.
   Alias: n

.PARAMETER access_token
   Optional access token for authenticating with the Kubernetes cluster.
   If not provided, the function will utilize the default authentication settings.
   Alias: t

.EXAMPLE
   CreateMasterServiceAccount -namespace "mynamespace" -access_token "myAccessToken123"

.NOTES
   You are verified to be sure if you want to continue performing this action. This action will change the environment.
   Be sure you are authorized to do so.

.OUTPUTS
   Success or error messages regarding the creation and validation of service accounts, roles, and bindings.

#>
Function CreateMasterServiceAccount {
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param(
        [Parameter(Mandatory = $true)]
        [Alias("n")]
        [string]$namespace,
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$access_token
    )

    if($PSCmdlet.ShouldProcess("$namespace")){
        # Retrieve the list of namespaces
        $namespaceArray = Get-NameSpaceArray
        # Check if the namespace exists in the array
        if (-not ($namespace -in $namespaceArray)) {
            Write-Host "Namespace '$namespace' does not exist. Stopping process"
            return
        }
        # Ask for the necessary details
        $role = Read-Host -Prompt "Please provide the role name"
        $serviceAccountName = Read-Host -Prompt "Please provide the service account name"
        $roleBindingName = Read-Host -Prompt "Please provide the role binding name"

        # Output the values for verification or use
        Write-Output "Role: $role"
        Write-Output "Service Account Name: $serviceAccountName"
        Write-Output "Role Binding Name: $roleBindingName"
        Write-Output "For namespace: $namespace"
        Perform-KubectlCommand -Action "create" -Type "sa" -Namespace $namespace -ExtraCommand "${serviceAccountName}" -Token $access_token 
        Perform-KubectlCommand -Action "create" -type "role" -namespace $namespace -extracommand "${role} --verb=* --resource=*" -token $access_token 
        Perform-KubectlCommand -Action "create" -type "rolebinding" -namespace $namespace -extracommand "${roleBindingName} --role=${role} --serviceaccount=${namespace}:${serviceAccountName}" -token $access_token 
        
        Write-Output "Tried all creating function"
        $getCreatedSa = Perform-KubectlCommand -Action "get" -type "sa" -namespace $namespace -extracommand "${serviceAccountName}" -token $access_token 
        $getCreatedRole = Perform-KubectlCommand -Action "get" -type "role" -namespace $namespace -extracommand "${role}" -token $access_token 
        $getCreatedRoleBinding = Perform-KubectlCommand -Action "get" -type "rolebinding" -namespace $namespace -extracommand "${roleBindingName}" -token $access_token 

        if ([string]::IsNullOrEmpty($getCreatedSa)) {
            Write-Host "Something went wrong while creating the Service account " -ForegroundColor Red
        }
        elseif ([string]::IsNullOrEmpty($getCreatedRole)) {
            Write-Host "Something went wrong while creating the role  " -ForegroundColor Red
        }
        elseif ([string]::IsNullOrEmpty($getCreatedRoleBinding)) {
            Write-Host "Something went wrong while creating the rolebinding " -ForegroundColor Red
        }
        else{
            Write-Host "Succesfully created a powerfull account in namespace: $namespace good luck!" -ForegroundColor Green
        }
    }
    else {
        Write-Output "Operation cancelled by user."
    }

}