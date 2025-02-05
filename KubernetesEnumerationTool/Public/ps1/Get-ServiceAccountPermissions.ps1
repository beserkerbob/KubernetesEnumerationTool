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

    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }

    # Your logic for enumerating authorization 
    Write-Output "Enumerating authorization..." -ForegroundColor Yellow
    $namespacesArray = Get-NameSpaceArray
    $actionNamespaceMap = @{}
    $uniqueNamespacesArray = $namespacesArray | Sort-Object | Get-Unique

    $SaAccounts = ""  # Ensure $data is initialized

    if($serviceAccount -eq "all" -or
            -not $PSBoundParameters.ContainsKey('serviceAccount') -or [string]::IsNullOrEmpty($serviceAccount)){
        foreach ($ns in $uniqueNamespacesArray) {
            Write-Host "Service accounts in namespace: $ns"
            $data = kubectl get sa -n $ns -o jsonpath='{.items[*].metadata.name}' 2>&1 | Out-String
            # Check if the output starts with "Error from server (Forbidden)"
            if ($data -like "Error from server (Forbidden)*") {
                # Do nothing if forbidden
                continue
            }
            # Remove new lines from the data
            $data = $data -replace "`r?`n", " "
            # Append the result to the data
            $SaAccounts += $data
            $SaAccounts += " "
        }
                # Trim any leading or trailing whitespace
        $SaAccounts = $SaAccounts.Trim()
        $ServiceAccountArray = $SaAccounts -split " " | Sort-Object | Get-Unique
        Write-Host "$ServiceAccountArray"
        # Perform the kubectl auth can-i command for each service account name
        foreach ($Name in $ServiceAccountArray) {
            foreach ($Internalnamespace in $uniqueNamespacesArray) {
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

                    $canIListResult | ForEach-Object {
                        $columns = $_ -split '\s\s+'
                        # Construct a unique action key from relevant columns
                        $actionKey = "$($columns[0])|$($columns[1])|$($columns[2])|$($columns[3])"
        
                        if (-not $actionNamespaceMap.ContainsKey($actionKey)) {
                            $actionNamespaceMap[$actionKey] = @([System.Collections.Generic.List[string]]::new(), [System.Collections.Generic.List[string]]::new())
                        }
        
                        # Add the namespace to the list if not already present
                        if (-not $actionNamespaceMap[$actionKey][0].Contains($Internalnamespace)) {
                            $actionNamespaceMap[$actionKey][0].Add($Internalnamespace)
                        }
        
                        # Add the service account to the list if not already present
                        if (-not $actionNamespaceMap[$actionKey][1].Contains($cleanName)) {
                            $actionNamespaceMap[$actionKey][1].Add($cleanName)
                        }
                    }

                    # Output formatted results
                    # $entries | Format-Table -AutoSize                            
                    # Write-Host ""
                
                }
            }
        } 
        
        # Now, display the aggregated results in a table
        $aggregatedResults = foreach ($entry in $actionNamespaceMap.GetEnumerator()) {
            $columns = $entry.Key -split '\|'
            [PSCustomObject]@{
                Resources         = $columns[0]
                NonResourceURLs   = $columns[1]
                ResourceNames     = $columns[2]
                Verbs             = $columns[3]
                Namespaces        = [string]::Join(", ", $entry.Value[0])
                ServiceAccounts   = [string]::Join(", ", $entry.Value[1])
            }
        }
        
        # Sort the results by the 'Resources' property
        $sortedResults = $aggregatedResults | Sort-Object -Property Resources

        # Display the sorted results in a table
        $sortedResults | Format-Table -Wrap -AutoSize
        $sortedResults | Format-Table -Wrap -AutoSize | Out-String -Width 250 | Out-File -FilePath "outputServiceAccountPermissionRequest.txt"
        Write-Host "Analyzing the output For interesting rights"
        Get-AnalyzedOutputCanIList -CanIListOutput $sortedResults -DoICreateMasterServiceAccount $DoICreateMasterServiceAccount 
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