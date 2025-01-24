<#
.SYNOPSIS
Enumerates and analyzes the permissions of Kubernetes service accounts within specified namespaces.

.DESCRIPTION
The `Get-ServiceAccountPermissions` function evaluates the authorization levels of service accounts in a Kubernetes cluster. It checks whether the specified or all service accounts have execution and listing permissions within namespaces, providing detailed output. This facilitates understanding the scope and capabilities of different service accounts in terms of Kubernetes resource access.

.PARAMETER serviceAccount
Specifies the service account to evaluate. Use "Myself" to check the calling user's permissions or "all" to assess permissions for all service accounts.

.PARAMETER DoICreateMasterServiceAccount
A boolean value indicating whether to analyze the output of permissions for creating a potential master service account.

.OUTPUTS
Returns detailed permission information for service accounts, indicating whether they have execution and listing capabilities within specified namespaces.

.EXAMPLE
Get-ServiceAccountPermissions -serviceAccount "Myself"

Checks the permissions of the calling user for executing pod commands across all namespaces.

.EXAMPLE
Get-ServiceAccountPermissions -serviceAccount "all" -DoICreateMasterServiceAccount $true

Analyzes all service accounts to determine execution and listing permissions, potentially identifying master service account creation opportunities.

.NOTES
- Requires `kubectl` command-line tool to be configured and accessible for running authorization checks against the Kubernetes API.
- Uses the `Get-AnalyzedOutputCanIList` function to further analyze permissions and potentially identify elevated access rights.
- End users should have adequate permissions to query service account details and perform authorization checks across the cluster.

#>
function Get-ServiceAccountPermissions{   
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$serviceAccount,
        [Parameter(Mandatory = $false)]
        [bool]$DoICreateMasterServiceAccount = $false
    )
    # Your logic for enumerating authorization 
    Write-Output "Enumerating authorization..." -ForegroundColor Yellow
    $namespacesArray = Get-NameSpaceArray
    foreach ($namespace in $namespacesArray) {
        if ($serviceAccount -eq "Myself"){
            Write-Host "Can i exec pods in namespace:" -ForegroundColor Yellow -NoNewline
            Write-Host "$namespace"-ForegroundColor Green
            # Run the kubectl command and capture the output
            $canIResult = kubectl auth can-i get pods --subresource=exec -n $namespace
        }
        elseif($serviceAccount -eq "all"){
            foreach ($ns in $namespacesArray) {
                Write-Host "Service accounts in namespace: $ns"
                $data = kubectl get sa -n $ns -o jsonpath='{.items[*].metadata.name}' | Out-String
                # Check if the output starts with "Error from server (Forbidden)"
                if ($data -like "Error from server (Forbidden)*") {
                    # Do nothing if forbidden
                    continue
                }
                $NameArray = $data -split " "
                # Perform the kubectl auth can-i command for each service account name
                foreach ($Name in $NameArray) {
                    foreach ($Internalnamespace in $namespacesArray) {
                        $cleanName = $Name -replace "(`r|`n)", ""
                        if ([string]::IsNullOrEmpty($cleanName)) {
                            continue;
                        }
                        Write-Host "Using $cleanName as serviceaccount name" -ForegroundColor Yellow
                        $canIResultexecPod = kubectl auth can-i get pods --subresource=exec --as "system:serviceaccount:${Internalnamespace}:${cleanName}" 2>$null
                        if ([string]::IsNullOrEmpty($canIResultexecPod)) {
                            Write-Host "I have no exec permissions for service account: $cleanName in namespace: $Internalnamespace using system:serviceaccount:${Internalnamespace}:${cleanName}"-ForegroundColor Red
                        }
                        else{
                            Write-Host "I have exec permissions for service account: $cleanName in namespace: $Internalnamespace using system:serviceaccount:${Internalnamespace}:${cleanName}" -ForegroundColor Green

                        }
                        $canIListResult = kubectl auth can-i --list --as "system:serviceaccount:${Internalnamespace}:${cleanName}" 2>$null
                        if ([string]::IsNullOrEmpty($canIListResult)) {
                            Write-Host "I have no list permissions for service account: $cleanName in namespace: $Internalnamespace using system:serviceaccount:${Internalnamespace}:${cleanName}"-ForegroundColor Red
                        }
                        else{
                            Write-Host "I have list permissions for service account: $cleanName in namespace: $Internalnamespace using system:serviceaccount:${Internalnamespace}:${cleanName}" -ForegroundColor Green
                            $canIListResult 
                            Write-Host ""
                            Write-Host "Analyzing the output For interesting rights"
                            Get-AnalyzedOutputCanIList -CanIListOutput $canIListResult -DoICreateMasterServiceAccount $DoICreateMasterServiceAccount 
                        }
                    }
                } 
            }
        }   
        else{
            Write-Host "Service accounts in namespace: " -ForegroundColor Yellow -NoNewline

            Write-Host "Checking permissions for service account:"-ForegroundColor Yellow -NoNewline
            Write-Host " $serviceAccount"  -ForegroundColor Green
            Write-Host "in namespace:"-ForegroundColor Yellow -NoNewline
            Write-Host "$namespace"  -ForegroundColor Green
            $canIExecuteResult = kubectl auth can-i get pods --subresource=exec --as $serviceAccount -n $namespace
        }

        # Check the output and change the text color accordingly
        if ($canIExecuteResult -eq "yes") {
            Write-Host "You have permission to execute in $namespace" -ForegroundColor Green
        } 
        elseif ($canIExecuteResult -eq "no") {
            Write-Host "You do not have permission to execute in $namespace." -ForegroundColor Red
        } 
        else {
            Write-Host "Unexpected result: $canIExecuteResult" -ForegroundColor Yellow
        }
    }
}