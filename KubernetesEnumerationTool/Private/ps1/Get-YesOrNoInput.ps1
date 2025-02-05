function Get-YesOrNoInput {
    do {
        # Prompt the user for input
        $response = Read-Host "Please enter 'yes' or 'no'"

        # Normalize the input to lowercase to simplify comparisons
        $response = $response.ToLower()

        # Check if the input is valid
        if ($response -eq 'yes' -or $response -eq 'y') {
            return $true
        } elseif ($response -eq 'no' -or $response -eq 'n') {
            return $false
        } else {
            Write-Host "Invalid input. Please enter 'yes' or 'no'."
        }
    } while ($true)
}