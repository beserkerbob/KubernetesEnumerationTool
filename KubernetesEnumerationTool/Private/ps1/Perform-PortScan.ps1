function Perform-PortScan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetHost,
        [Parameter(Mandatory = $false)]
        [int[]]$Ports = 30000..32767  # Default to scanning ports for nodeports
    )

    foreach ($port in $Ports) {
        try {
            # Attempt to establish a TCP connection to the specified port
            $connection = [System.Net.Sockets.TcpClient]::new($TargetHost, $port)
            if ($connection.Connected) {
                Write-Host "Port $port is open on $TargetHost" -ForegroundColor Green
                $connection.Close()
            }
        } catch {
            # Handle exceptions (e.g., port is closed)
            Write-Host "Port $port is closed on $TargetHost" -ForegroundColor Red
        }
    }
}