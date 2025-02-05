function SearchForPublicNodePort{  
    [CmdletBinding()]
param(
    # Parameter token is optional and can be used for acessing with other access_tokens
    [Parameter(Mandatory = $false)]
    [Alias("t")]
    [String] $accesstoken,
    # Parameter token is optional and can be used for acessing with other access_tokens
    [Parameter(Mandatory = $true)]
    [boolean] $nmap = $false
    )

    $nodeInfo = Kubectl get nodes -o json | ConvertFrom-Json

    foreach ($item in $nodeInfo.items) {
        $NodeAdresses = $item.status.addresses
        foreach($address in $NodeAdresses){
            if($address.type -eq "ExternalIP"){
                Write-Host "externalIp Found"
                Write-Host "Performing full connect scan to search for open NodePorts"
                if($nmap){
                    Write-Host "nmap activate"
                    nmap.exe -T4 $address.address -p 30000-32767
                }
                else{
                    Perform-PortScan -TargetHost $address.address
                }
            }
            elseif($address.type -eq "InternalIP"){
                Write-Host InternIP Found: $address.address
                if($nmap){
                    Write-Host "nmap activate"
                    nmap.exe -T4 $address.address -p 30000-32767

                }
                else{
                    Perform-PortScan -TargetHost $address.address
                }
            }
        }
    }

    Write-Host "Listing nodeports on regular services"
    $result = kubectl get services -A -o=custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[*],PORT(S):.spec.ports[*].port,NODEPORT(S):.spec.ports[*].nodePort,TARGETPORT(S):.spec.ports[*].targetPort,SELECTOR:.spec.selector'  2>$null
    if([string]::IsNullOrEmpty($result)){
        $namespacesArray = Get-NameSpaceArray
        foreach ($namespace in $namespacesArray) {
            $result = kubectl get services -n $namespace -o=custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[*],PORT(S):.spec.ports[*].port,NODEPORT(S):.spec.ports[*].nodePort,TARGETPORT(S):.spec.ports[*].targetPort,SELECTOR:.spec.selector'  2>$null
            $result
        }
    }
    else{
        $result
    }
}