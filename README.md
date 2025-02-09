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

- Expansion to AWS and k3s platforms.
- Transition from `kubectl` usage to API integrations.
- Rewriting in Go to enhance performance.
- Making the application more robust.
- For metadata endpoint search for lolbins which can be used to retrieve information from already deployed pods (limits the need of pod create rights / and delete for cleanup)
- Include other exploit techniques like patching a pod etc.
- Writing different formats for yaml for jobs, cronjobs based and use based on the given privileges.
- implement also validating the use of ValidatingAdmissionPolicy
- Implement advice and example configurations which would help secure the system

## Legal Disclaimer
This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. Use this application at your own risk.
