powershell

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
         # When we have rolebinding service account creations and rolerights

        # Ask for the necessary details
        $role = Read-Host -Prompt "Please provide the role name"
        $serviceAccountName = Read-Host -Prompt "Please provide the service account name"
        $roleBindingName = Read-Host -Prompt "Please provide the role binding name"

        # Output the values for verification or use
        Write-Output "Role: $role"
        Write-Output "Service Account Name: $serviceAccountName"
        Write-Output "Role Binding Name: $roleBindingName"
        Perform-KubectlCommand -action "create" -type "sa " -namespace $namespace -extracommand "${serviceAccountName}" -token $access_token 
        Perform-KubectlCommand -action "create" -type "role " -namespace $namespace -extracommand "${role} --verb=* --resource=*" -token $access_token 
        Perform-KubectlCommand -action "create" -type "rolebinding " -namespace $namespace -extracommand "${roleBindingName} --role=${role} --serviceaccount=${namespace}:${serviceAccountName}" -token $access_token 
        
        Write-Output "Tried all creating function"
        $getCreatedSa = Perform-KubectlCommand -action "get" -type "sa " -namespace $namespace -extracommand "${serviceAccountName}" -token $access_token 
        $getCreatedSa = Perform-KubectlCommand -action "get" -type "role " -namespace $namespace -extracommand "${role}" -token $access_token 
        $getCreatedSa = Perform-KubectlCommand -action "get" -type "rolebinding " -namespace $namespace -extracommand "${roleBindingName}" -token $access_token 

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