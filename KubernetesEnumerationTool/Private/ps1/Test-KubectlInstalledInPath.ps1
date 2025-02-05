    
    
    
Function Test-KubectlInstalledInPath {
    # Ensure kubectl is available
    if ((Get-Command kubectl -ErrorAction SilentlyContinue) -eq $null) {
        Write-Error "kubectl is not installed or not in your PATH."
        return $false;
    }
    return $true;
}