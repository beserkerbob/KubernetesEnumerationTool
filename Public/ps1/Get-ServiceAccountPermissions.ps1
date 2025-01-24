<#
.SYNOPSIS
   Retrieves and analyzes service account permissions in each namespace and optionally creates a master service account.

.DESCRIPTION
   The Get-ServiceAccountPermissions function iterates through all namespaces, retrieves service accounts, and checks their permissions using `kubectl auth can-i`.
   It analyzes the output for each service account and can trigger the creation of a master service account if specified.

.PARAMETER token
   An optional string that provides an access token for accessing Kubernetes resources. This token is used to authenticate `kubectl` commands.

.PARAMETER DoICreateMasterServiceAccount
   A boolean flag that, if true, will analyze permissions and may trigger the creation of a master service account using the Get-AnalyzedOutputCanIList function. Default is $false.

.NOTES
   This function relies on external functions such as Get-NameSpaceArray, Perform-KubectlCommand, and Get-AnalyzedOutputCanIList.
   Ensure these are defined and operational within the environment.

.OUTPUTS
   Displays the names of service accounts, their permissions, and potentially initiates the creation of master resources based on permissions and the specified flag.

.EXAMPLE
   Get-ServiceAccountPermissions -token 'myAccessToken' -DoICreateMasterServiceAccount $true

#>
Function Get-ServiceAccountPermissions  {
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [String] $accesstoken,
        [Parameter(Mandatory = $false)]
        [Alias("createSA")]
        [Bool] $DoICreateMasterServiceAccount = $false
    )
    $namespacesArray = Get-NameSpaceArray
    foreach ($ns in $namespacesArray) {
        Write-Host "Service accounts in namespace: "-ForegroundColor Yellow -NoNewline
        Write-Host "$ns" -ForegroundColor Green
        $data = Perform-KubectlCommand  -action "get" -type "sa" -namespace $ns -extracommand '-o jsonpath="{.items[*].metadata.name}"' -accesstoken $accesstoken 
        # Check if the variable $data is an empty string
        if ([string]::IsNullOrEmpty($data)) {
            Write-Host "Error from server Forbidden to retrieve service account for namespace $ns" -ForegroundColor Red
            continue
        }
        $NameArray = $data -split " "
        # Perform the kubectl auth can-i command for each service account name
        foreach ($Name in $NameArray) {
            $cleanName = $Name -replace "(`r|`n)", ""
            Write-Host "Checking permissions for service account:"-ForegroundColor Yellow -NoNewline
            Write-Host " $cleanName "  -ForegroundColor Green -NoNewline
            Write-Host "in namespace:"-ForegroundColor Yellow -NoNewline
            Write-Host "$ns "  -ForegroundColor Green -NoNewline
            Write-Host "using " -ForegroundColor Yellow -NoNewline
            Write-Host "system:serviceaccount:${ns}:${cleanName}" -ForegroundColor Green 
            $resultCanIList = kubectl auth can-i --list --as "system:serviceaccount:${ns}:${cleanName}" 
            $resultCanIList
            Write-Host "Now analyzing the data"
            Get-AnalyzedOutputCanIList -CanIListOutput $resultCanIList -DoICreateMasterServiceAccount $DoICreateMasterServiceAccount

        }
        Write-Host ""
    }
} 

