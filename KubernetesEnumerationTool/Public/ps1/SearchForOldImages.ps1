#Still only works for docker.io
function SearchForOldImages{  
    [CmdletBinding()]
param(
    # Parameter token is optional and can be used for acessing with other access_tokens
    [Parameter(Mandatory = $false)]
    [Alias("t")]
    [String] $accesstoken
    )

    $nodeImages = @()

    $ImageMetaData = @()
    $nodeInfo = Kubectl get nodes -o json | ConvertFrom-Json


    foreach ($item in $nodeInfo.items) {
        $nodeImages = $item.status.images
        foreach ($imageName in $nodeImages.names) {
            if($imageName.StartsWith("docker.io")){

                # Regex pattern to extract repositoryName, applicationName, and tag or digest
                $pattern = "docker\.io\/([^\/]+)\/([^@:\s]+)(?::([^:\s]+))?(?:@sha256:([a-fA-F0-9]+))?"
                if ($imageName -match $pattern) {
                    
                    # Check if the image with the same repositoryName and imageName already exists
                    $existing = $ImageMetaData | Where-Object {
                        $_.repositoryName -eq $matches[1] -and
                        $_.imageName -eq $matches[2]
                    }
                    if($existing){
                        if($matches[3]){
                           $existing.tagName = $matches[3] 
                        }
                        if($matches[4]){
                            $existing.digest = $matches[4] 
                        }
                    }
                    else{
                        $ImageMetaData += [PSCustomObject]@{
                            repositoryName = $matches[1]
                            imageName = $matches[2]
                            tagName = $matches[3]
                            digest = $matches[4]
                        }
                    }
                }
            }
        }
    }

    # Output the ImageMetaData for verification
    $ImageMetaData | ForEach-Object {
        Write-Host "Repository Name: $($_.repositoryName)"
        Write-Host "Image Name: $($_.imageName)"
        Write-Host "Tag Name: $($_.tagName)"
        Write-Host "Digest: $($_.digest)"
        Write-Host ""
        $url = "https://hub.docker.com/v2/repositories/$($_.repositoryName)/$($_.imageName)/tags?page_size=5&page=1&ordering=last_updated&name="

        # Use Invoke-RestMethod to send the HTTP GET request
        $response = Invoke-RestMethod -Uri $url -Method Get
        # Output the data or process it further
        foreach($item in $response.results){
            # Remove the 'sha256:' prefix
            $cleanedString = $item.digest -replace "sha256:", ""

            if($($_.tagName) -lt $item.name -and $item.name -ne "latest" -and $item.name -ne "snapshot"){
                Write-Host "The following image with imagename: " -ForegroundColor Yellow -NoNewline
                Write-Host $($_.repositoryName)/$($_.imageName)  -ForegroundColor Green 
                Write-Host "Has a newer version. a newer version is: "  -ForegroundColor Yellow -NoNewline
                Write-Host $item.name -ForegroundColor Green 
                Write-Host "instead of current used version: " -ForegroundColor Yellow -NoNewline
                Write-Host $($_.tagName) -ForegroundColor Red
                Write-Host "This was pushed at:" -ForegroundColor Yellow -NoNewline
                Write-Host $item.tag_last_pushed -ForegroundColor Green
            }
            
            elseif($($_.tagName) -eq $item.name -and $($_.digest) -ne $cleanedString){
                Write-Host "The following image with imagename: " -ForegroundColor Yellow -NoNewline
                Write-Host $($_.repositoryName)/$($_.imageName)  -ForegroundColor Green 
                Write-Host "Looks like the tag is the same however the digest is different"
                Write-Host The old digest: $($_.digest)
                Write-Host The new Digest: $cleanedString
                Write-Host "This was pushed at:" -ForegroundColor Yellow -NoNewline
                Write-Host $item.tag_last_pushed -ForegroundColor Green
            }
        }
    } 
}