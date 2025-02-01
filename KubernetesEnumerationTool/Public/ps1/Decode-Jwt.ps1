<#
.SYNOPSIS
   Decodes a JSON Web Token (JWT) into its constituent parts.

.DESCRIPTION
   The Decode-Jwt function takes a JWT as input and splits it into its header, payload, and signature parts. 
   It decodes the Base64Url encoded header and payload sections, leaving the signature as is.

.PARAMETER JwtToken
   The JWT string to decode. It must have exactly three parts separated by dots.

.OUTPUTS
   A PSCustomObject containing the decoded Header, Payload, and the raw Signature of the JWT.

.EXAMPLE
   $jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
   $decodedJwt = Decode-Jwt -JwtToken $jwt
   Write-Output $decodedJwt.Header
   Write-Output $decodedJwt.Payload

.NOTES
   - Requires the ConvertFrom-Base64Url function to decode the Base64Url encoded segments.
   - The signature part of the JWT is typically not decoded as it is meant for verification rather than display.

#>
function Decode-Jwt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,Position=0)]
        [Alias("j")]
        [string]$JwtToken
    )

    # Split the token into its parts
    $parts = $JwtToken -split '\.'

    if ($parts.Length -ne 3) {
        throw "Invalid JWT: expected 3 parts separated by dots."
    }

    # Decode each part
    $header = ConvertFrom-Base64Url $parts[0]
    $payload = ConvertFrom-Base64Url $parts[1]
    $signature = $parts[2] # Usually, the signature isn't decoded, but you can if needed

    Write-Host "Header:" $header
    Write-Host "Payload:" $payload

    # Output results
   return [PSCustomObject]@{
        Header = $header
        Payload = $payload
        Signature = $signature
    }
}