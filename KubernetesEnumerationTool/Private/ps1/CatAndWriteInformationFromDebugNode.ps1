<#
.SYNOPSIS
Executes a command on a Kubernetes node via a debug container and writes the output to a file.

.DESCRIPTION
The `CatAndWriteInformationFromDebugNode` function utilizes `kubectl debug` to execute specified commands on a Kubernetes node. It captures the command output, displays it, and appends the results to a specified file. This function is particularly useful for auditing or extracting specific files or data from nodes by creating a temporary debug pod on the target node.

.PARAMETER namespace
The Kubernetes namespace in which the debug pod should be launched. This parameter is optional and defaults to the current context if not provided.

.PARAMETER token
An optional authentication token for Kubernetes API access. Use this to authenticate when running commands if your setup requires token-based authentication.

.PARAMETER command
A required parameter specifying the command to run on the node. This can include commands like 'cat' to view file contents.

.PARAMETER nodeName
The name of the node on which to execute the debug command. This is a required parameter to identify the target node.

.PARAMETER fileName
The name of the file where the command output should be saved. This is a required parameter for result logging.

.EXAMPLE
CatAndWriteInformationFromDebugNode -nodeName "node01" -command "cat /etc/hosts" -fileName "hosts.txt"

Launches a debug container on "node01" to display and save the contents of `/etc/hosts` to "hosts.txt".

.EXAMPLE
CatAndWriteInformationFromDebugNode -nodeName "node02" -namespace "default" -command "ls /var/log" -fileName "logs.txt"

Lists directory contents from `/var/log` on "node02" within the "default" namespace and appends the information to "logs.txt".

.NOTES
- Requires `kubectl` to be installed and configured to perform debug operations on the Kubernetes cluster.
- This function may be used in sensitive environments; ensure authorized execution in line with security policies.
- Handles command outputs and paths smartly, ensuring data is logged even from complex directory structures.

#>
function CatAndWriteinformationFromDebugNode{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$namespace,
        [Parameter(Mandatory = $false)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$command,
        [Parameter(Mandatory = $true)]
        [string]$nodeName,
        [Parameter(Mandatory = $true)]
        [string]$fileName

    )
    $commandArgs = $command -split ' '
    
    $PathsFromNode = kubectl debug node/$nodeName -it -q --image=ubuntu -n $namespace -- $commandArgs
    if ($commandArgs[0] -eq 'cat') {
        # Perform the action if the command is 'cat'
        Write-Host "Outputting result from $command"
        Write-Host "$PathsFromNode" 
        # Add new lines before and after the content
        $resultWithNewLines = "`n$PathsFromNode`n"
        $resultWithNewLines | Out-File -FilePath "$fileName" -Append       # You can call another function, execute a script, etc.
    } else{
        foreach($PathFromNode in $PathsFromNode){
            Write-Host "Listing info from $PathFromNode"
            Write-Host ""
                        # Check if the colon exists and process accordingly somethimes the path contains the details of the token information for example which results in a tolong path
            if ($PathFromNode -match ":") {
                # Extract everything before the colon
                $modifiedString = $PathFromNode.Split(":")[0]
            } else {
                # Use the whole string if no colon is found
                $modifiedString = $PathFromNode
            }

            $result = kubectl debug node/$nodeName -it -q --image=ubuntu -n $namespace -- cat $modifiedString
            Write-Host "$result"
            $resultWithNewLines = "`n$result`n"
            $resultWithNewLines | Out-File -FilePath "$fileName" -Append 
            Write-Host ""
        }
    }

}
