# KubernetesEnumerationTool

## Overview

KubernetesEnumerationTool is designed to enhance your understanding of Kubernetes applications. This tool helps you find necessary information across namespaces and checks for best practices in deployed pods. It identifies issues like improper service account token mounts, usage of `hostIPC`, or enabling `privileged` mode. Additionally, it searches for secrets and currently implements two methods for potential exploitation to the node.

## Features

- **Namespace Actions**: Retrieve namespaces where you can perform specific actions.
- **Secrets Discovery**: Access Kubernetes secrets across different namespaces.
- **Release Information**: Determine release information.
- **Image Updates**: Identify if there are newer images available (currently using Docker Hub).
- **Node Exploitation**: Exploit to the node using node debug and `hostIPC`, retrieve sensitive information, and validate constraints (currently focusing on Azure).
- **Network Policy Check**: Validate the Kubernetes network policy settings.
- **Best Practice Validation**: Ensure pods are adhering to best practices (e.g., avoiding `privileged`, `hostIPC`, etc.).
- **DoS Testing**: Conduct a Kubernetes Denial of Service (DOS) test.

## Installation

The tool is currently implemented using PowerShell modules.  and can be easily installed from the git directory

```
git clone https://github.com/beserkerbob/KubernetesEnumerationTool.git  
cd KubernetesEnumerationTool
Import-Module .\KubernetesEnumerationTool -Force
```

## Usage

After installation it easy to use just ron the functions specified: 

Like if you want to Test if you can exploit to the node (and it will create some pods for this) just use:
`Test-ExploitabilityToNode`

![image](https://github.com/user-attachments/assets/363b5533-fc59-4e69-a4a0-fc107f3f8101)


you can also find old images using: `SearchForOldImages`

![image](https://github.com/user-attachments/assets/b3e970d1-d05a-41fc-80a2-143eee8fe1f2)


Or check if there are some best practices missing with:
`Get-PodBestPracticeAnalysis`

![image](https://github.com/user-attachments/assets/50463d6f-62fd-4905-9efb-66c8034a4231)


Now the following functions are available:
  - CreateMasterServiceAccount
  - Decode-Jwt
  - Get-FileExtensionsFromVolumesInNodes
  - Get-KubernetesConstraints
  - Get-KubernetesNetworkPolicy
  - Get-KubernetesReleaseInfo
  - Get-KubernetesSecrets
  - Get-MetaDataInformation
  - Get-NamespacesWhereICanPerformAction
  - Get-NodeInformation
  - Get-PodBestPracticeAnalysis
  - Get-RBAC
  - Get-ResourceLoadPods
  - Get-ResourceQuotas
  - Get-SensitiveInformationFromNode
  - Get-ServiceAccountPermissions
  - SearchForOldImages
  - SearchForPublicNodePort
  - Test-ExploitabilityToNode
  - Test-KubernetesDOS

## Future Plans Include

- [ ] Expansion to AWS and k3s platforms.
- [ ] Transition from `kubectl` usage to API integrations.
- [ ] Rewriting in Go to enhance performance.
- [ ] Making the application more robust.
- [ ] For metadata endpoint search for lolbins which can be used to retrieve information from already deployed pods (limits the need of pod create rights / and delete for cleanup)
- [ ] Include other exploit techniques like patching a pod etc.
- [x] Writing different formats for yaml for jobs, cronjobs based and use based on the given privileges.
- [ ] implement also validating the use of ValidatingAdmissionPolicy
- [ ] Implement advice and example configurations which would help secure the system
- [ ] Validate the anonymous authentication property kubelet.
- [ ] Create an option to enable anonymous authentication (based on: https://github.com/Azure/AKS/blob/master/examples/kubelet/enable-anonymous-auth-for-non-rbac.yaml)
 - [x] Find pods which run the start command as sudo.
 - [ ] find best practices for windows (the windowsOptions, Host Process)
 - [ ] validate runAsUserName for windows process
 - [ ] check for shareProcessNamespace
 - [ ] write advise for user namespace https://kubernetes.io/docs/tasks/configure-pod-container/user-namespaces/
 - [x] make use of reverse shell possibilities
 - [ ] Include PodDisruptionBudget.
 - [ ]  using kernel modules to breakout / Implement afvide on how to block those (/etc/modprobe.d/kubernetes-blacklist.conf)

## Legal Disclaimer
This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. Use this application at your own risk.

### Important Notes:
Ethical Use: The tools and scripts on this website should be used only on systems you own or have explicit permission to test. Unauthorized use of these tools on systems that you do not own or have permission to test is illegal and unethical.

Legal Compliance: Ensure that your use of these tools complies with all relevant laws and regulations in your jurisdiction. The author of this website assumes no responsibility for any legal consequences arising from the use or misuse of these tools.

No Warranty: These tools and scripts are provided “as is”, without warranty of any kind, express or implied. Use them at your own risk. The author does not guarantee that these tools will work as expected or that they are free from bugs or errors.

Responsibility: By using the tools and scripts described on this website, you agree that you are responsible for any consequences that may result from their use. The author is not liable for any damage, loss, or legal issues that may arise from using these tools.
