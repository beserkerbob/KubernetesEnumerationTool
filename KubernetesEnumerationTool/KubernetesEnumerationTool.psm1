$directorySeparator = [System.IO.Path]::DirectorySeparatorChar
$moduleName = $PSScriptRoot.Split($directorySeparator)[-1]
$moduleManifest = $PSScriptRoot + $directorySeparator + $moduleName + '.psd1'
$publicFunctionsPath = $PSScriptRoot + $directorySeparator + 'Public' + $directorySeparator + 'ps1'
$privateFunctionsPath = $PSScriptRoot + $directorySeparator + 'Private' + $directorySeparator + 'ps1'
$classesPath =  $PSScriptRoot + $directorySeparator + 'Classes' + $directorySeparator + 'ps1'
$currentManifest = Test-ModuleManifest $moduleManifest

$aliases = @()
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$publicFunctions | ForEach-Object { 
    try {
        Write-Verbose "Dot-sourcing $($_.FullName)"
        . $_.FullName
    } catch {
        Write-Error "Error sourcing $($_.FullName): $_"
    }
}
$privateFunctions | ForEach-Object { . $_.FullName }
#$classes | ForEach-Object { . $_.FullName }

$publicFunctions | ForEach-Object { # Export all of the public functions from this module

    # The command has already been sourced in above. Query any defined aliases.
    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }

}
$functionsToExport = $publicFunctions.BaseName
Write-Host "PrivateFunctions"
if ($env:PSModuleTest -eq 'true') {
    Write-Host "testing is true"

    $privateFunctions | ForEach-Object { # Export all of the private functions from this module if Psmodule test
        Write-Host "Export module member ${_.BaseName}"

            Export-ModuleMember -Function $_.BaseName
    }
    $functionsToExport = $publicFunctions.BaseName + $privateFunctions.BaseName

}
Write-Host $functionsToExport
$functionsAdded = $publicFunctions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.Keys}
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $functionsToExport}
$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.Keys}
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $aliases}

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) {

    try {

        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $moduleManifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
        if ($publicFunctions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $functionsToExport) }

        Update-ModuleManifest @updateModuleManifestParams

    }
    catch {

        $_ | Write-Error

    }

}