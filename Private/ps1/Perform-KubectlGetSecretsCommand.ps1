<#
.SYNOPSIS
Retrieves and processes secrets from specified namespaces within a Kubernetes cluster.

.DESCRIPTION
The `Perform-KubectlGetSecretsCommand` function executes a command to obtain secrets from a specified namespace in a Kubernetes cluster. It verifies access permissions and, upon successful retrieval, outputs the secrets while invoking further analysis. This function aids in managing and understanding secret data across namespaces.

.PARAMETER token
An optional string for authentication when accessing the Kubernetes API, ensuring secure secret retrieval operations.

.PARAMETER givenNamespace
A string representing the namespace from which to retrieve and process secrets. This parameter specifies the focus area within the cluster.

.OUTPUTS
Displays the secrets retrieved from the specified namespace and processes them using further analysis commands if access permissions allow.

.EXAMPLE
Perform-KubectlGetSecretsCommand -givenNamespace "development"

Attempts to retrieve and process secrets from the "development" namespace, outputting results if permissions permit.

.EXAMPLE
Perform-KubectlGetSecretsCommand -token "abcd1234" -givenNamespace "production"

Executes the secret retrieval command in the "production" namespace using the specified token for authentication.

.NOTES
- Relies on the `Perform-KubectlCommand` function to execute the underlying secrets retrieval process, necessitating proper configuration and permissions.
- Invokes `SearchingSecrets` to conduct additional analysis or operations on the retrieved secret data.
- Ensures that namespace access permissions are checked, and alerts if access is denied, maintaining security best practices.

#>
Function Perform-KubectlGetSecretsCommand{
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [String] $token,
        [Parameter(Mandatory = $false)]
        [string]$givenNamespace
    )
    $secretNamespace = Perform-KubectlCommand  -action "get" -type "secrets" -namespace $givenNamespace -extracommand '-o wide' -token $token 
    if ([string]::IsNullOrEmpty($secretNamespace)) {
            Write-Host "No permissions to retrieve secrets on $givenNamespace" -ForegroundColor Red 
            continue
    }
    Write-Host "Found the following secrets for $givenNamespace" -ForegroundColor Green
    $secretNamespace
    SearchingSecrets -token $token -givenNamespace $givenNamespace -allNameSpaces "no"
}