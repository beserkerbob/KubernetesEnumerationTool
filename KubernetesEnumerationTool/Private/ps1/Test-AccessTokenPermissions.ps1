<#
.SYNOPSIS
Tests and analyzes permissions from a provided access token in a Kubernetes environment.

.DESCRIPTION
The `Test-AccessTokenPermissions` function verifies the permissions associated with a given access token, typically formatted as a JWT, against a Kubernetes namespace. It decodes the access rights, saves the results for further inspection, and identifies potential security risks or elevated permissions that may indicate the capability to create or manipulate significant resources within the cluster.

.PARAMETER access_token
A string representing the access token to be analyzed. The function assesses whether the token format suggests it's a JWT and interprets permissions accordingly.

.PARAMETER DoICreateMasterServiceAccount
A boolean indicating whether to explore actions that might lead to the creation of a master service account if the token’s permissions indicate extensive access. Defaults to `$False`.

.OUTPUTS
Generates and writes a report of token permissions to a text file and conducts a detailed examination for critical access rights patterns.

.EXAMPLE
Test-AccessTokenPermissions -access_token "eyJhbGciOiJIUzI1NiIsIn..."

Evaluates the given JWT access token, decodes its permissions, and checks for broad access rights across the cluster.

.EXAMPLE
Test-AccessTokenPermissions -access_token "eyJhbGciOiJIUzI1NiIsIn..." -DoICreateMasterServiceAccount $True

Decodes the token, analyzes permissions, and considers creating a master service account if substantial permissions are detected.

.NOTES
- Assumes JWT format for the token when attempting to decode access rights.
- Requires the `kubectl` tool for querying access rights within the Kubernetes environment.
- Utilizes `Get-AnalyzedOutputCanIList` for thorough analysis of permissions, supporting security evaluations and strategic decisions.

#>
Function Test-AccessTokenPermissions{
    param(
        [Parameter(Mandatory = $true)]
        [string]$access_token,        
        [Parameter(Mandatory = $false)]
        [Bool]$DoICreateMasterServiceAccount = $false,
        [Parameter(Mandatory = $true)]
        [string]$namespace

    )
    if ($access_token.StartsWith("eyJ")) {
        Write-Output "The string looks like a jwt token trying to list rights."
        $accessRightsDecodedToken = kubectl auth can-i --list --token=$access_token -n $namespace 
        $accessRightsDecodedToken | Out-File -FilePath "all_auth_can-I_with_token${namespace}.txt"
        Write-Output "Wrote the items to a file Searching for interesting information items with *, create, impersonate or delete."
        Get-AnalyzedOutputCanIList -CanIListOutput $accessRightsDecodedToken -access_token $access_token -DoICreateMasterServiceAccount $DoICreateMasterServiceAccount
        

    }
}