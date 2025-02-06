#KubernetesEnumerationTool
##Overview
KubernetesEnumerationTool is designed to enhance your understanding of Kubernetes applications. This tool helps you find necessary information across namespaces and checks for best practices in deployed pods. It identifies issues like improper service account token mounts, usage of hostIPC, or enabling privileged mode. Additionally, it searches for secrets and currently implements two methods for potential exploitation to the node.

##Features
Namespace Actions: Retrieve namespaces where you can perform specific actions.
Secrets Discovery: Access Kubernetes secrets across different namespaces.
Release Information: Determine release information.
Image Updates: Identify if there are newer images available (currently using Docker Hub).
Node Exploitation: Exploit to the node using node debug and hostIPC, retrieve sensitive information, and validate constraints (currently focusing on Azure).
Network Policy Check: Validate the Kubernetes network policy settings.
Best Practice Validation: Ensure pods are adhering to best practices (e.g., avoiding privileged, hostIPC, etc.).
DoS Testing: Conduct a Kubernetes Denial of Service (DOS) test.
Implementation
The tool is currently implemented using PowerShell modules.

##Future plans include:

Expansion to AWS and k3s platforms.
Transition from kubectl usage to API integrations.
Rewriting in Go to enhance performance.
Making the application more robust
