<#
.SYNOPSIS
Generates and formats a table report for Kubernetes pod analysis results, highlighting deviations from best practices.

.DESCRIPTION
The `FormatTableAnalyzingResource` function formats analysis results of Kubernetes pods into a readable table. It highlights pods that fail to meet certain best practices, outputting the results both to the console and a text file. The function emphasizes why specific practices are recommended and provides a concise report to aid in addressing identified gaps.

.PARAMETER tekst
A mandatory string parameter explaining the importance of the best practice being evaluated, providing context as to why pods should adhere to this standard.

.PARAMETER podInformation
An object containing details about pods that do not conform to the specified best practice. This data is used to generate formatted reports.

.PARAMETER title
A mandatory string parameter serving as the title of the analysis report, specifying the best practice or standard being evaluated.

.PARAMETER properties
A string indicating which pod object properties to display in the formatted table, allowing for customizable output depending on the analysis focus.

.OUTPUTS
Outputs a formatted table in the console and a corresponding text file that details Kubernetes pods not meeting the specified best practice.

.EXAMPLE
FormatTableAnalyzingResource -tekst "Implementing AppArmor reduces vulnerability risks." -podInformation $podsWithoutAppArmor -title "AppArmor" -properties "PodName, Namespace"

Formats and outputs an analysis report for pods missing AppArmor configuration, explaining the importance of AppArmor in security.

.NOTES
- Relies on proper data structure within `$podInformation` for accuracy in table formatting and file output.
- Enhances administrative efforts by providing both immediate visual feedback and persistent text documentation for further reference.
- The choice of properties should align with the data structure within the `$podInformation` parameter for accurate table generation.

#>

Function FormatTableAnalyzingResource  {
    [CmdletBinding()]
    param(
        # Parameter tekst is required and explains why this best practische should be implemented 
        [Parameter(Mandatory = $true)]
        [String] $tekst,        
        # Parameter tekst is required and explains why this best practische should be implemented 
        [Parameter(Mandatory = $true)]
        [Object] $podInformation,
        # Parameter tekst is required and explains why this best practische should be implemented 
        [Parameter(Mandatory = $true)]
        [string] $title,
        # Parameter tekst is required and explains why this best practische should be implemented 
        [Parameter(Mandatory = $true)]
        [string] $properties
    ) 
    # Output some information about the pod 
    if ($podInformation.Count -eq 0) {
        Write-Host "All running pods have $title."-ForegroundColor Green
    } else {
        $trimmedVariable = $title -replace ' ', ''
        Write-Host "The following pods don't have $title :" -ForegroundColor Red
        $podInformation | Format-Table -Property @property -AutoSize
        $podInformation | Format-Table -Property $property -AutoSize | Out-File -FilePath "AnalyzingPodResource$trimmedVariable.txt"
        Write-Host "The above pods don't have a $title : "
        Write-Host "$tekst"
    }
}