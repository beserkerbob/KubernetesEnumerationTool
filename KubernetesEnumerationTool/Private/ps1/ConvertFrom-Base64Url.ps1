<#
.SYNOPSIS
   Converts a Base64Url-encoded string to a UTF-8 string.

.DESCRIPTION
   The ConvertFrom-Base64Url function decodes a Base64Url-encoded string, which is a URL-safe version of Base64 encoding. 
   This function replaces URL-safe characters with standard Base64 characters and adds necessary padding before decoding.

.PARAMETER Base64Url
   The Base64Url-encoded string that you wish to decode. This parameter is mandatory.

.OUTPUTS
   Returns the decoded UTF-8 string from the Base64Url input.

.EXAMPLE
   $decodedString = ConvertFrom-Base64Url -Base64Url "SGVsbG8gd29ybGQ"
   Write-Output $decodedString

   This example decodes a Base64Url-encoded string back to "Hello world".

.NOTES
   Base64Url encoding is commonly used in URL contexts to avoid reserved characters.

#>
function ConvertFrom-Base64Url {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,Position=0)]
        [Alias("b")]
        [string]$Base64Url
    )
    # Replace URL-safe characters and pad with '=' if necessary.
    $base64 = $Base64Url.Replace('-', '+').Replace('_', '/')
    switch ($base64.Length % 4) {
        0 { break }  # No padding necessary
        2 { $base64 += "==" } # Add 2 padding characters
        3 { $base64 += "=" }  # Add 1 padding character
        default { return "Invalid base64url input: incorrect length" }
    }
    try {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
    } catch {
        throw "Decoding Base64Url failed: $_"
    }
}

