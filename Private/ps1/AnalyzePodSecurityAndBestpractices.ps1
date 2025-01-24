<#
.SYNOPSIS
Evaluates Kubernetes pods for compliance with security best practices and operational guidelines.

.DESCRIPTION
The `AnalyzePodSecurityAndBestPractices` function inspects Kubernetes pods to ensure they adhere to established security protocols and best practices. This involves checking for owner references to identify orphaned pods, evaluating security settings (like AppArmor and seccomp profiles), and confirming the implementation of resource limits and probes. The function outputs detailed reports highlighting areas where pods may not meet security and operational standards.

.PARAMETER KubectlObject
A mandatory parameter representing the Kubernetes pod data to be analyzed, typically obtained from a `kubectl get pods` command in JSON format.

.OUTPUTS
Outputs structured reports identifying pods that deviate from recommended security practices across various dimensions such as privilege escalation, resource limits, capability management, and container probes.

.EXAMPLE
AnalyzePodSecurityAndBestPractices -KubectlObject $kubectlData

Runs an evaluation on the provided Kubernetes pod data to identify security and best practice concerns, outputting results for further action.

.NOTES
- Utilizes helper function `FormatTableAnalyzingResource` to present findings in a readable table format.
- Requires access to Kubernetes pod details, typically achieved through prior retrieval using the Kubernetes API.
- Functions as a diagnostic tool to aid Kubernetes administrators in enforcing container security and operational stability.

#>
Function AnalyzePodSecurityAndBestPractices{
    param(
        # Parameter token is optional and can be used for acessing with other access_tokens
        [Parameter(Mandatory = $true)]
        [Object] $KubectlObject
    )
    # Create a list to hold orphaned pods
    $orphanedPods = @()
    # Create a list to hold pods using the latest tag
    $podsUsingLatest = @()
    #Create a list to hold pods without liviness probes
    $podsWithoutLivenessProbe = @()
    #Create a list to hold pods without readiness probes
    $podsWithoutReadinessProbe = @()
    #Create a list to hold pods without startup probes
    $podsWithoutStartupProbe = @()
    #Create a list to hold pods without Prestop 
    $podsWithoutPreStop = @()
    #Create a list to hold pods without Prestop 
    $podsWithoutRunAsUser = @()
    #Create a list to hold pods which didn't have set Allowprivilegesescaltion to false 

    $podsAllowingPrivilegeEscalation = @()

    $podsNotEnforcingReadOnlyFileSystem = @()

    $podsNotDroppingAllCapabilities = @()

    $podsAllowingPrivileged = @()
    $podsNotHavingLimits = @()

    $podsWithSpecificCapabilities= @()
    $podsWithNoRamAndCPULimits= @()

    $podsWithNoSeccompProfile = @()

    $podsWithoutAppArmor = @()

    $hasRunAsUser = $false

    # Iterate over each pod
    foreach ($pod in $KubectlObject.items) {
        # Check if the pod has any owner references
        $foundCapabilities = @()
        $hasNoCpuLimit = $true
        $hasNoRamLimit = $true   
        $hasSeccompProfile = $false
        $podNamespace = $pod.metadata.namespace
        $podName = $pod.metadata.name

        $usesAppArmor = $false

        # Check for AppArmor annotations on the pod
        if ($pod.metadata.annotations) {
            foreach ($annotation in $pod.metadata.annotations.Keys) {
                if ($annotation -like "container.apparmor.security.beta.kubernetes.io/*") {
                    $usesAppArmor = $true
                    break
                }
            }
        }
        # Add to the results if AppArmor is not used
        if (-not $usesAppArmor) {
            $podsWithoutAppArmor += [PSCustomObject]@{
                PodName   = $podName
                Namespace = $podNamespace
            }
        }
        # Check pod-level security context
        if ($pod.spec.securityContext -and $pod.spec.securityContext.runAsUser) {
            $hasRunAsUser = $true
        }
        if (-not $pod.metadata.ownerReferences) {
            # If there are no owner references, it's orphaned
            $orphanedPods += [PSCustomObject]@{
                PodName = $podName
                Namespace = $podNamespace
            }
        }
        if ($pod.spec.securityContext -and $pod.spec.securityContext.capabilities) {
            $capabilities = $pod.spec.securityContext.capabilities.add
            if ($capabilities) {
                foreach ($capability in $capabilities) {
                    if ($capability -in "BPF", "DAC_READ_SEARCH", "NET_Admin", "SYS_admin", `
                                        "SYS_boot", "SYS_module", "SYS_PTRACE", "SYS_RawIO", "Syslog") {
                        $foundCapabilities += $capability
                    }
                }
            }
        }

        # Check pod-level security context for seccompProfile
        if ($pod.spec.securityContext -and $pod.spec.securityContext.seccompProfile) {
            $hasSeccompProfile = $true
        }
        #Loop trough container level security context 
        foreach ($container in $pod.spec.containers) {
            #Check For security Context
            if ($container.securityContext -and $container.securityContext.runAsUser) {
                $hasRunAsUser = $true
            }
            if ($container.securityContext -and $container.securityContext.seccompProfile) {
                $hasSeccompProfile = $true
            }
            if ($container.securityContext -and $container.securityContext.allowPrivilegeEscalation -ne $false) {
                $podsAllowingPrivilegeEscalation += [PSCustomObject]@{
                    PodName   = $podName
                    Namespace = $podNamespace
                }
            }
            if ($container.securityContext -and $container.securityContext.readOnlyRootFilesystem -ne $true) {
                $podsNotEnforcingReadOnlyFileSystem += [PSCustomObject]@{
                    PodName   = $podName
                    Namespace = $podNamespace
                }
            }
            if ($container.securityContext -and $container.securityContext.privileged -ne $false) {
                $podsAllowingPrivileged += [PSCustomObject]@{
                    PodName   = $podName
                    Namespace = $podNamespace
                }
            }
            # Set flags to false if limits are found
            if ($container.resources) {
                if ($container.resources.limits.cpu) {
                    $hasNoCpuLimit = $false
                }
                if ($container.resources.limits.memory) {
                    $hasNoRamLimit = $false
                }
            }
            if ($container.securityContext -and $container.securityContext.capabilities){
                $capabilities = $container.securityContext.capabilities.add
                if ($capabilities) {
                    foreach ($capability in $capabilities) {
                        if ($capability -in "BPF", "DAC_READ_SEARCH", "NET_Admin", "SYS_admin", `
                                            "SYS_boot", "SYS_module", "SYS_PTRACE", "SYS_RawIO", "Syslog") {
                            $foundCapabilities += $capability
                        }
                    }
                }
            }
            if ($container.securityContext -and $container.securityContext.capabilities.drop -ne "All") {
                $podsNotDroppingAllCapabilities += [PSCustomObject]@{
                    PodName   = $podName
                    Namespace = $podNamespace
                }
            }
            #Check For use of latest tag
            if ($container.image -match ":latest$") {
                $podsUsingLatest += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Image     = $container.image
                }
            }
            #Check For use of latest tag
            if ($container.resources -and $container.resources.limits -ne $false) {
                $podsNotHavingLimits += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Image     = $container.image
                }
            }

            #Check LivenessProbe
            if (-not $container.livenessProbe) {
                $podsWithoutLivenessProbe += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Container = $container.name
                }
            }
            # Check readiness probe
            if (-not $container.readinessProbe) {
                $podsWithoutReadinessProbe += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Container = $container.name
                }
            }

            # Check startup probe
            if (-not $container.startupProbe) {
                $podsWithoutStartupProbe += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Container = $container.name
                }
            }

            #Check for prestop fucntion for each pod
            if (-not $container.lifecycle.preStop) {
                $podsWithoutPreStop += [PSCustomObject]@{
                    PodName = $podName
                    Namespace = $podNamespace
                    Container = $container.name
                }
            }
            # Check for CPU and RAM limits

        }
            # If the pod and its containers do not have runAsUser, add to the list
        if (-not $hasRunAsUser) {
            $podsWithoutRunAsUser += [PSCustomObject]@{
                PodName   = $podName
                Namespace = $podNamespace
            }
        }
        # If any specific capabilities were found, add the pod and capabilities to the list
        if ($foundCapabilities.Count -gt 0) {
            $podsWithSpecificCapabilities += [PSCustomObject]@{
                PodName        = $podName
                Namespace      = $podNamespace
                Capabilities   = $foundCapabilities -join ", "
            }
        }
        # Add to the results if a specific seccompProfile implementation is present
        if (-not $hasSeccompProfile) {
            $podsWithNoSeccompProfile += [PSCustomObject]@{
                PodName         = $podName
                Namespace       = $podNamespace
            }
        }
            # Add to the output list only if capabilities are found and there are no CPU or RAM limits
        if ($hasNoCpuLimit -or $hasNoRamLimit) {
            $podsWithNoRamAndCPULimits += [PSCustomObject]@{
                PodName        = $podName
                Namespace      = $podNamespace
                NoCpuLimits    = $hasNoCpuLimit
                NoRamLimits    = $hasNoRamLimit
            }
        }
    }
    
    FormatTableAnalyzingResource -title "No AppArmor" -podInformation $podsWithoutAppArmor -properties "PodName, Namespace" -tekst "They included no Apparmor, AppArmor provides mandatory access controls to restrict program capabilities. reducing the risk of vulnerabilities."

    FormatTableAnalyzingResource -title "No SeccompProfile" -podInformation $podsWithNoSeccompProfile -properties "PodName, Namespace" -tekst "They included no seccomprofile, seccomprofile enhances Kubernetes pod security by restricting system calls that containers can make to the kernel, reducing the risk of vulnerabilities."

    FormatTableAnalyzingResource -title "Limits for CPU and RAM" -podInformation $podsWithNoRamAndCPULimits -properties "PodName, Namespace, CPULimits, MemoryLimits" -tekst "They included no limits for CPU or RAM which is a bad practisch and could result in resource starvation"

    FormatTableAnalyzingResource -title "save Capabilities" -podInformation $podsWithSpecificCapabilities -properties "PodName, Namespace, Capabilities" -tekst "They included one of the following dangerous capabilities BPF, DAC_READ_SEARCH, NET_Admin, Sys_admin, Sys_boot, Sys_module, Sys-PTRACE, Sys_RawIO, Syslog"

    FormatTableAnalyzingResource -title "Not having limits implemented" -podInformation $podsNotHavingLimits -properties "PodName, Namespace, Image" -tekst "You should always drop limits in combination with resources to be sure that a pod can't cause resource starvation "

    FormatTableAnalyzingResource -title "Not dropping all capabilities" -podInformation $podsNotDroppingAllCapabilities -properties "PodName, Namespace, Image" -tekst "You should always drop all capabilities of a  pods to be sure that least privileged is implemented. Now the team needs to implement themself which capabilities should be added"

    FormatTableAnalyzingResource -title "Allowing privileged containers" -podInformation $podsAllowingPrivileged -properties "PodName, Namespace, Image" -tekst "You should always make that pods are not running as root. This should be enforced using this property"

    FormatTableAnalyzingResource -title "not implemented readonlyfilesystem" -podInformation $podsNotEnforcingReadOnlyFileSystem -properties "PodName, Namespace, Image" -tekst "You should always make that pods are bound to an readonly file system to block some specific explotation paths"

    FormatTableAnalyzingResource -title "AllowPrivilegeEscalation" -podInformation $podsAllowingPrivilegeEscalation -properties "PodName, Namespace, Image" -tekst "You should always make sure that pods are not allowed to escalate privileges."

    FormatTableAnalyzingResource -title "a proper tag and use the'latest' tag." -podInformation $podsUsingLatest -properties "PodName, Namespace, Image" -tekst "You should avoid using the :latest tag when deploying containers in production as it is harder to track which version of the image is running and more difficult to roll back properly."

    FormatTableAnalyzingResource -title "orphaned pods" -podInformation $orphanedPods -properties "PodName, Namespace" -tekst "therefor will not be rescheduled in the event of a node failure Make sure they are deployed through a Replicaset or Deployment"

    FormatTableAnalyzingResource -title "readiness probes" -podInformation $podsWithoutReadinessProbe -properties "PodName, Namespace, Container" -tekst "therefor it is possible that traffic is already reaching the application before the pod is completly functioning resulting in unexpected behaviour"

    FormatTableAnalyzingResource -title "Startup probes" -podInformation $podsWithoutStartupProbe -properties "PodName, Namespace, Container" -tekst "Startup probe allow to delay the initial check by liveness which could cause deadlock or wrong result"

    FormatTableAnalyzingResource -title "pre-stop" -podInformation $podsWithoutPreStop -properties "PodName, Namespace, Container" -tekst " therefor they aren't gracefully terminated When applicable, use pre-stop hooks to ensure graceful termination of a container" 

    FormatTableAnalyzingResource -title "runAsUser" -podInformation $podsWithoutRunAsUser -properties "PodName, Namespace, Container" -tekst "as a security context" 
}