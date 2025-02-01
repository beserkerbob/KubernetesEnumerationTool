Function Perform-SearchSecrets{
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token,
        [Parameter(Mandatory = $false)]
        [string]$givenNamespace,
        [Parameter(Mandatory = $true)]
        [string]$allNameSpaces
    )
    try { $_ = (Get-Command jq -ErrorAction Stop).Path } catch { Write-Host "For this to work jq is required can be installed from https://jqlang.github.io/jq/download/ "; exit 1 }    
    Write-Host "Trying to retrieve more information for each Role"
        If($allNameSpaces -eq "no"){
            $secretJsonNamespace = Perform-KubectlCommand  -action "get" -type "secrets" -namespace $givenNamespace -extracommand '-o json' -token $token 
        }
        Elseif ($allNameSpaces -eq "yes"){
            $secretJsonNamespace = Perform-KubectlCommand  -action "get" -type "secrets" -extracommand '-o json -A' -token $token 
        }
        else {
            Write-Host "You must specify allNamespaces to be no or yes"
            continue;
        }
            Write-Host "Trying to find a token specific tokens"
            $FoundToken = $secretJsonNamespace | jq '.items[].data | to_entries[] | select(.key | test(\"PAT|Password|Username|User|Pass|token|secret|Bearer|API|Key\"; \"i\")) | {(.key): .value}' 2>$null
            if ([string]::IsNullOrEmpty($FoundToken)) {
                Write-Host "No interesting information found in data" -ForegroundColor Red
            }
            else{
                Write-Host "Found possible interesting information Listing below" -ForegroundColor Green
                $FoundToken

                Write-Host ""
                Write-Host "trying regex to decode interesing information "
                # Regular Expression to Match Values
                $regexPattern = '"[^"]+":\s*"([^"]+)"'

                # Extract and print values
                foreach ($line in $FoundToken -split "\r?\n") {
                    if ($line -match $regexPattern) {
                        $value = $matches[1]
                        $key = $matches[0]
                         # $FoundToken = $secretJsonNamespace | jq '.items[] | select(.data.token != null) | .data.token' | ConvertFrom-Json 2>$null
                        Write-Host "The raw Base64 decoded value of the following key: value pare $key ="
                        $decodedToken = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$value"))
                        Write-Host "$decodedToken" -ForegroundColor Green
                        Test-AccessTokenPermissions -access_token $decodedToken -namespace $givenNamespace
                    }
                }
            }
}