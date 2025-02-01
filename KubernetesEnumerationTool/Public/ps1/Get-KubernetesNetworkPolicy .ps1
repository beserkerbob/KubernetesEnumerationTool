<#
.SYNOPSIS
    Retrieves and displays the current Kubernetes Network Policies in a cluster.

.DESCRIPTION
    The Get-KubernetesNetworkPolicy function queries Kubernetes network policies, providing insight into the existing 
    network restrictions within the cluster. The function uses an access token for authentication if provided, 
    enabling retrievals with appropriate permissions.

    It lists all network policies, highlighting scenarios where no policies are defined,
    which may imply open communication between all pods, external networks, and metadata endpoints.

    Detailed descriptions of each network policy are displayed, including associated pod selectors 
    and bound pods, facilitating a clear overview of policy application within the cluster.

.PARAMETER accesstoken
    An optional security token for authentication purposes. Providing an access token may enable 
    access to restricted network policy information within the Kubernetes cluster.

.EXAMPLE
    Get-KubernetesNetworkPolicy

    Retrieves network policies using default permissions without an access token, listing all accessible policies.

.EXAMPLE
    Get-KubernetesNetworkPolicy -accesstoken "your-access-token"

    Uses a specified access token to authenticate the request and retrieve network policies, allowing access 
    to potentially limited data based on the token's permissions.

.NOTES
    The function depends on an auxiliary function, Perform-KubectlCommand, which facilitates the execution of kubectl commands.
    Ensure necessary configurations and permissions are in place to execute kubectl commands within the cluster.

    The function assumes access to kubectl, which should be installed and configured with cluster access.

.LINK
    https://kubernetes.io/docs/concepts/services-networking/network-policies/ - Detailed guide on Kubernetes Network Policies.
#>

function Get-KubernetesNetworkPolicy {
    [CmdletBinding()]
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [String] $accesstoken
    )
    $networkPolicies = Perform-KubectlCommand -action "get" -type "networkpolicy" -extracommand '-o json' -token $accesstoken 
    Write-Host "We found:" -ForegroundColor Yellow -NoNewline

    if($networkPolicies.items.Count -eq 0){
        Write-Host "$($networkPolicies.items.Count) networkPolicies " -ForegroundColor red
        Write-Host "Every pod can communicate with each other, to the outside and to the metadata endpoint probably" -ForegroundColor Green 
        continue;
    }
    Write-Host $networkPolicies.items.Count -ForegroundColor Green -NoNewline
    Write-Host " networkPolicies. There names are:"-ForegroundColor Yellow
    foreach ($policy in $networkPolicies.items) {
        Write-Host $policy.metadata.name -ForegroundColor Green 
    }
    Write-Host ""
    Write-Host "Retrieving information of each NetworkPolicy"
    Write-Host ""
    foreach ($policy in $networkPolicies.items) {
        $name = $policy.metadata.name
        $podSelectorString = $policy.spec.podSelector.matchLabels
        $podSelector = $podSelectorString -replace '@{(.*)}', '$1'
        #Write-Host "NetworkPolicy Name: $name"
        Write-Host "NetworkPolicyName  " -ForegroundColor Yellow -NoNewline
        Write-Host "$name" -ForegroundColor Green

        if ($podSelector) {
            Write-Host "Has the PodSelectorName:"-ForegroundColor Yellow -NoNewline
            Write-Host $podSelector  -ForegroundColor Green
            Write-Host "" 
            Write-Host "The following pods have this policy bound to them:" -ForegroundColor Yellow
            Perform-KubectlCommand -action "get" -type "pods" -extracommand "-A --selector=${podSelector}" -token $accesstoken 
            Write-Host "" 
        } 
        else{
            Write-Host "There is no Podselector for $name"-ForegroundColor Red
            Write-Host "" 
        }

        Write-Host "The description of the networkPolicy" -ForegroundColor Yellow
        Write-Host "" 
        kubectl describe networkpolicy $name
    }
}